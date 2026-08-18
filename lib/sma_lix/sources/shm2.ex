defmodule SmaLix.Sources.SHM2 do
  @moduledoc """
  Source for the SMA Sunny Home Manager 2 (and compatible energy meters),
  reading SMA Speedwire multicast datagrams. Port of `plugins/sources/SHM2`.

  Unlike the polling sources, this is event-driven: it opens a multicast UDP
  socket in active mode and decodes each datagram (`SmaLix.Speedwire`) as it
  arrives, throttled to at most one processed frame per `:update_freq` seconds.
  """

  use SmaLix.Source
  require Logger

  @protocol 0x6069

  @impl true
  def setup(config) do
    group = Keyword.fetch!(config, :multicast_group)
    port = Keyword.fetch!(config, :multicast_port)
    bind = Keyword.get(config, :bind_address, "0.0.0.0")

    with {:ok, group_addr} <- :inet.parse_address(String.to_charlist(group)),
         {:ok, bind_addr} <- :inet.parse_address(String.to_charlist(bind)),
         {:ok, socket} <-
           :gen_udp.open(port,
             mode: :binary,
             active: 100,
             reuseaddr: true,
             add_membership: {group_addr, bind_addr}
           ) do
      state = %{
        socket: socket,
        prefix: Keyword.get(config, :sensor_prefix, "SHM2."),
        update_freq_ms: Keyword.get(config, :update_freq, 2) * 1000,
        last_processed: 0
      }

      {:ok, state}
    else
      {:error, reason} ->
        Logger.critical("Could not join SHM2 multicast socket: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def handle_message({:udp_passive, socket}, state) do
    :inet.setopts(socket, active: 100)
    {:noreply, state}
  end

  def handle_message({:udp_closed, _socket}, state) do
    Logger.error("SHM2 UDP socket closed unexpectedly")
    {:stop, :socket_closed, state}
  end

  def handle_message({:udp_error, _socket, reason}, state) do
    Logger.error("SHM2 UDP socket error: #{inspect(reason)}")
    {:stop, reason, state}
  end

  def handle_message({:udp, _socket, _ip, _port, data}, state) do
    now = System.monotonic_time(:millisecond)

    if now - state.last_processed >= state.update_freq_ms do
      case decode(data, state.prefix) do
        {:ok, pairs} -> {:emit, pairs, %{state | last_processed: now}}
        :ignore -> {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  def handle_message(_msg, state), do: {:noreply, state}

  # ── Decoding a single datagram into store pairs ─────────────────────────────

  defp decode(data, prefix) do
    emdata = SmaLix.Speedwire.decode(data)

    if emdata["protocol"] == @protocol and is_integer(emdata["serial"]) do
      {:ok, device_info_pairs(emdata, prefix) ++ measurement_pairs(emdata, prefix)}
    else
      :ignore
    end
  end

  defp device_info_pairs(emdata, prefix) do
    serial = emdata["serial"]

    %{
      "name" => "SMA Sunny Home Manager 2",
      "model" => "EM/SHM/SHM2",
      "manufacturer" => "SMA",
      "identifiers" => serial,
      "sw_version" => emdata["speedwire-version"]
    }
    |> Enum.map(fn {key, value} -> {"#{prefix}#{serial}.device_info.#{key}", value} end)
  end

  defp measurement_pairs(emdata, prefix) do
    serial = emdata["serial"]

    emdata
    |> Enum.flat_map(fn {key, value} ->
      cond do
        String.ends_with?(key, "unit") -> []
        key in ["serial", "protocol", "speedwire-version"] -> []
        true -> measurement_pair(key, value, emdata, serial, prefix)
      end
    end)
  end

  defp measurement_pair(key, value, emdata, serial, prefix) do
    case topic(key, serial, prefix) do
      :skip -> []
      name -> [{name, {value, emdata[key <> "unit"]}}]
    end
  end

  # Sorts measurement keys into topic hierarchies, mirroring the upstream
  # if/elif ladder exactly (order matters).
  defp topic(key, serial, prefix) do
    p = "#{prefix}#{serial}"

    cond do
      String.contains?(key, "p1") -> "#{p}.p.1.#{key}"
      String.contains?(key, "q1") -> "#{p}.q.1.#{key}"
      String.contains?(key, "s1") -> "#{p}.s.1.#{key}"
      String.contains?(key, "p2") -> "#{p}.p.2.#{key}"
      String.contains?(key, "q2") -> "#{p}.q.2.#{key}"
      String.contains?(key, "s2") -> "#{p}.s.2.#{key}"
      String.contains?(key, "p3") -> "#{p}.p.3.#{key}"
      String.contains?(key, "q3") -> "#{p}.q.3.#{key}"
      String.contains?(key, "s3") -> "#{p}.s.3.#{key}"
      String.starts_with?(key, "p") -> "#{p}.p.#{key}"
      String.starts_with?(key, "q") -> "#{p}.q.#{key}"
      String.starts_with?(key, "s") -> "#{p}.s.#{key}"
      String.contains?(key, "1") -> "#{p}.1.#{key}"
      String.contains?(key, "2") -> "#{p}.2.#{key}"
      String.contains?(key, "3") -> "#{p}.3.#{key}"
      String.contains?(key, "cosphi") or String.contains?(key, "frequency") -> "#{p}.#{key}"
      true -> :skip
    end
  end

  @impl true
  def sensors, do: SmaLix.Sources.SHM2.Sensors.list()
end
