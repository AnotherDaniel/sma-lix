defmodule SmaLix.Sinks.Mqtt do
  @moduledoc """
  Publishes collected data to a plain MQTT broker. Port of `plugins/sinks/mqtt`.

  Values are published on change (via `handle_update/3`), and the full set is
  republished every `:update_freq` seconds (via `handle_flush/2`). Store keys map
  to topics by replacing `.` with `/` (e.g. `SHM2.1234.p.pconsume` →
  `SHM2/1234/p/pconsume`).

  The underlying `Tortoise311` connection handles reconnection with backoff on
  its own, so the manual reconnect loop from the Python version is unnecessary.
  """

  use SmaLix.Sink
  require Logger

  @impl true
  def setup(config) do
    client_id = "smahub#{Keyword.get(config, :ident_postfix, "")}"

    connection_opts =
      [
        client_id: client_id,
        server: server(config),
        handler: {Tortoise311.Handler.Default, []},
        clean_session: false
      ]
      |> maybe_put(:user_name, config[:username])
      |> maybe_put(:password, config[:password])

    case Tortoise311.Connection.start_link(connection_opts) do
      {:ok, _pid} ->
        state = %{
          client_id: client_id,
          publish_units: Keyword.get(config, :publish_units, false)
        }

        Logger.info("connecting to #{config[:address]}:#{config[:port]}")
        {:ok, state, Keyword.get(config, :update_freq, 60) * 1000}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def handle_update(key, value, state) do
    publish(key, value, state)
    {:ok, state}
  end

  @impl true
  def handle_flush(items, state) do
    for {key, value} <- items, do: publish(key, value, state)
    {:ok, state}
  end

  # ── Publishing ──────────────────────────────────────────────────────────────

  defp publish(key, value, state) do
    topic = String.replace(key, ".", "/")
    Tortoise311.publish(state.client_id, topic, payload(value, state.publish_units), qos: 0)
  end

  # Strip the unit unless the operator wants value/unit pairs published.
  defp payload({value, _unit}, false), do: to_string(value)
  defp payload({value, unit}, true), do: "(#{value}, '#{unit}')"
  defp payload(value, _publish_units), do: to_string(value)

  # ── Connection helpers ──────────────────────────────────────────────────────

  defp server(config) do
    host = config[:address]
    port = config[:port] || 1883

    case tls_versions(config[:tls]) do
      nil ->
        {Tortoise311.Transport.Tcp, host: host, port: port}

      versions ->
        opts = if config[:tls_insecure], do: [verify: :verify_none], else: []
        {Tortoise311.Transport.SSL, host: host, port: port, opts: [versions: versions] ++ opts}
    end
  end

  defp tls_versions("1"), do: [:"tlsv1.1"]
  defp tls_versions("2"), do: [:"tlsv1.2"]
  defp tls_versions(_), do: nil

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, _key, ""), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
