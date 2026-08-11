defmodule SmaLix.Sources.SmaHttpApi do
  @moduledoc """
  Shared polling logic for SMA devices exposing the local HTTP/JSON API used by
  Tripower X inverters and the EV Charger (SunSpec-style `IGULD:SELF`).

  In SMAHub these were two almost-identical ~15-30 KB files
  (`tripowerx.py`, `evcharger.py`); here the collection logic lives once and the
  two plugins (`SmaLix.Sources.TripowerX`, `SmaLix.Sources.EvCharger`) supply
  only their own configuration and sensor definitions.

  Authentication is lazy and self-healing: rather than logging in during startup
  (and giving up on failure, as upstream did), the token is (re)acquired inside
  `poll/1`, so a temporarily unreachable device simply retries on the next tick.
  """

  require Logger
  alias SmaLix.Helpers

  @login_timeout 5_000

  @doc "Builds initial state and requests periodic polling every `:update_freq` seconds."
  @spec setup(keyword()) :: {:ok, map(), non_neg_integer()}
  def setup(config) do
    state = %{
      config: config,
      base_url: "#{config[:protocol]}://#{config[:address]}",
      prefix: Keyword.get(config, :sensor_prefix, ""),
      group: SmaLix.Plugin.group(Keyword.get(config, :sensor_prefix, "")),
      ident_postfix: Keyword.get(config, :ident_postfix, ""),
      token: nil,
      device_info: nil
    }

    {:ok, state, Keyword.get(config, :update_freq, 2) * 1000}
  end

  @doc "Polls the device once, emitting device info and live measurements."
  @spec poll(map()) :: {:emit, [{String.t(), term()}], map()} | {:noreply, map()}
  def poll(state) do
    with {:ok, state} <- ensure_session(state),
         {:ok, measurements} <- fetch_live(state) do
      pairs = device_info_pairs(state) ++ measurement_pairs(measurements, state)
      {:emit, pairs, state}
    else
      :reauth ->
        # token expired; drop it and retry on the next tick
        {:noreply, %{state | token: nil}}

      {:error, reason} ->
        Logger.warning("poll failed: #{inspect(reason)}")
        {:noreply, %{state | token: nil}}
    end
  end

  # ── Session / auth ──────────────────────────────────────────────────────────

  defp ensure_session(%{token: token, device_info: di} = state)
       when is_binary(token) and is_map(di) do
    {:ok, state}
  end

  defp ensure_session(state) do
    with {:ok, token} <- login(state),
         {:ok, device_info} <- fetch_device_info(state, token) do
      {:ok, %{state | token: token, device_info: device_info}}
    end
  end

  defp login(state) do
    cfg = state.config

    result =
      Req.post(state.base_url <> "/api/v1/token",
        form: [
          grant_type: "password",
          username: cfg[:username],
          password: cfg[:password]
        ],
        receive_timeout: @login_timeout,
        retry: :transient,
        connect_options: tls_opts(cfg)
      )

    case result do
      {:ok, %{status: 200, body: %{"access_token" => token}}} ->
        {:ok, token}

      {:ok, %{status: 404}} ->
        {:error, :http_404}

      {:ok, %{body: _}} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_device_info(state, token) do
    url = state.base_url <> "/api/v1/plants/Plant:1/devices/IGULD:SELF"

    case Req.get(url, headers: auth(token), connect_options: tls_opts(state.config)) do
      {:ok, %{status: 200, body: dev}} when is_map(dev) ->
        {:ok, build_device_info(dev, state)}

      {:ok, %{status: status}} ->
        {:error, {:device_info_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_device_info(dev, state) do
    %{
      "name" => "#{dev["product"]}#{state.ident_postfix}",
      "configuration_url" => state.base_url,
      "identifiers" => dev["serial"],
      "model" => "#{dev["vendor"]}-#{dev["product"]}",
      "manufacturer" => dev["vendor"],
      "sw_version" => dev["firmwareVersion"]
    }
  end

  # ── Live measurements ───────────────────────────────────────────────────────

  defp fetch_live(state) do
    url = state.base_url <> "/api/v1/measurements/live"

    result =
      Req.post(url,
        headers: auth(state.token),
        json: [%{"componentId" => "IGULD:SELF"}],
        connect_options: tls_opts(state.config)
      )

    case result do
      {:ok, %{status: 200, body: data}} when is_list(data) -> {:ok, data}
      {:ok, %{status: 401}} -> :reauth
      {:ok, %{status: status}} -> {:error, {:live_status, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp device_info_pairs(%{device_info: di, prefix: prefix}) do
    serial = di["identifiers"]

    Enum.map(di, fn {key, value} ->
      {"#{prefix}#{serial}.device_info.#{key}", value}
    end)
  end

  defp measurement_pairs(measurements, state) do
    serial = state.device_info["identifiers"]

    Enum.flat_map(measurements, fn d ->
      name =
        d["channelId"]
        |> String.replace("Measurement.", "")
        |> String.replace("[]", "")

      dname = "#{state.prefix}#{serial}.#{name}"

      case d["values"] do
        [%{"value" => v} | _] ->
          [pair(dname, v, name, state.group)]

        [%{"values" => list} | _] when is_list(list) ->
          list
          |> Enum.with_index(1)
          |> Enum.map(fn {v, idx} -> pair("#{dname}.#{idx}", v, name, state.group) end)

        _ ->
          []
      end
    end)
  end

  defp pair(key, raw_value, name, group) do
    value = round_if_number(raw_value)

    case SmaLix.SensorRegistry.unit(group, name) do
      nil -> {key, value}
      unit -> {key, {value, unit}}
    end
  end

  defp round_if_number(value) do
    case Helpers.to_float(value) do
      {:ok, f} -> Float.round(f, 2)
      :error -> value
    end
  end

  # ── HTTP helpers ────────────────────────────────────────────────────────────

  defp auth(token), do: [{"authorization", "Bearer #{token}"}]

  defp tls_opts(config) do
    if Keyword.get(config, :verify_tls, false) do
      []
    else
      [transport_opts: [verify: :verify_none]]
    end
  end
end
