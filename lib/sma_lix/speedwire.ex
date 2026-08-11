defmodule SmaLix.Speedwire do
  @moduledoc """
  Decoder for SMA Speedwire energy-meter multicast datagrams.

  Ported from SMAHub's `utils/speedwiredecoder.py`, which in turn descends from
  datenschuft's SMA-EM (`david-m-m`, `datenschuft`). Where the Python version
  walked the datagram with manual offset arithmetic and `int.from_bytes`, this
  uses Elixir binary pattern matching, which expresses the wire format directly.

  `decode/1` returns a map of measurement name => value. Measurements carry a
  companion `"<name>unit"` entry; counters a `"<name>counter"` /
  `"<name>counterunit"` pair — matching the upstream key layout that the SHM2
  source depends on.

  Licensed GPL-2.0, as the upstream file.
  """

  # Scaling divisors per unit.
  @units %{
    "W" => 10,
    "VA" => 10,
    "var" => 10,
    "kWh" => 3_600_000,
    "kVAh" => 3_600_000,
    "kvarh" => 3_600_000,
    "A" => 1000,
    "V" => 1000,
    "°" => 1000,
    "Hz" => 1000
  }

  # channel_number => {name, actual_unit, counter_unit}
  @channels %{
    # totals
    1 => {"pconsume", "W", "kWh"},
    2 => {"psupply", "W", "kWh"},
    3 => {"qconsume", "var", "kvarh"},
    4 => {"qsupply", "var", "kvarh"},
    9 => {"sconsume", "VA", "kVAh"},
    10 => {"ssupply", "VA", "kVAh"},
    13 => {"cosphi", "°", nil},
    14 => {"frequency", "Hz", nil},
    # phase 1
    21 => {"p1consume", "W", "kWh"},
    22 => {"p1supply", "W", "kWh"},
    23 => {"q1consume", "var", "kvarh"},
    24 => {"q1supply", "var", "kvarh"},
    29 => {"s1consume", "VA", "kVAh"},
    30 => {"s1supply", "VA", "kVAh"},
    31 => {"i1", "A", nil},
    32 => {"u1", "V", nil},
    33 => {"cosphi1", "°", nil},
    # phase 2
    41 => {"p2consume", "W", "kWh"},
    42 => {"p2supply", "W", "kWh"},
    43 => {"q2consume", "var", "kvarh"},
    44 => {"q2supply", "var", "kvarh"},
    49 => {"s2consume", "VA", "kVAh"},
    50 => {"s2supply", "VA", "kVAh"},
    51 => {"i2", "A", nil},
    52 => {"u2", "V", nil},
    53 => {"cosphi2", "°", nil},
    # phase 3
    61 => {"p3consume", "W", "kWh"},
    62 => {"p3supply", "W", "kWh"},
    63 => {"q3consume", "var", "kvarh"},
    64 => {"q3supply", "var", "kvarh"},
    69 => {"s3consume", "VA", "kVAh"},
    70 => {"s3supply", "VA", "kVAh"},
    71 => {"i3", "A", nil},
    72 => {"u3", "V", nil},
    73 => {"cosphi3", "°", nil},
    # common
    36_864 => {"speedwire-version", "", nil}
  }

  @version_suffix %{1 => ".S", 2 => ".A", 3 => ".B", 4 => ".R", 5 => ".E", 6 => ".N"}

  @doc """
  Decodes a Speedwire datagram into a map of measurements.

  Returns an empty map for datagrams that don't carry the `"SMA"` header.
  """
  @spec decode(binary()) :: %{optional(String.t()) => term()}
  def decode(<<"SMA", _::binary>> = datagram) do
    <<
      _header::binary-size(12),
      datalength::unsigned-big-16,
      _skip1::binary-size(2),
      protocol::unsigned-big-16,
      _skip2::binary-size(2),
      serial::unsigned-big-32,
      _rest::binary
    >> = datagram

    datalength = datalength + 16

    base = %{"serial" => serial, "protocol" => protocol}

    decode_blocks(datagram, 28, datalength, base)
  end

  def decode(_datagram), do: %{}

  # ── OBIS block walk ─────────────────────────────────────────────────────────

  defp decode_blocks(datagram, position, datalength, acc) when position < datalength do
    <<measurement::unsigned-big-16, raw_type::unsigned-8, _::8>> =
      binary_part(datagram, position, 4)

    channel = Map.get(@channels, measurement)

    case datatype(raw_type, measurement) do
      :actual ->
        <<value::unsigned-big-32>> = binary_part(datagram, position + 4, 4)
        acc = put_actual(acc, channel, value)
        decode_blocks(datagram, position + 8, datalength, acc)

      :counter ->
        <<value::unsigned-big-64>> = binary_part(datagram, position + 4, 8)
        acc = put_counter(acc, channel, value)
        decode_blocks(datagram, position + 12, datalength, acc)

      :version ->
        raw = binary_part(datagram, position + 4, 4)
        acc = put_version(acc, channel, raw)
        decode_blocks(datagram, position + 8, datalength, acc)

      :unknown ->
        decode_blocks(datagram, position + 8, datalength, acc)
    end
  end

  defp decode_blocks(_datagram, _position, _datalength, acc), do: acc

  defp datatype(4, _measurement), do: :actual
  defp datatype(8, _measurement), do: :counter
  defp datatype(0, 36_864), do: :version
  defp datatype(_raw_type, _measurement), do: :unknown

  # ── Value placement ─────────────────────────────────────────────────────────

  defp put_actual(acc, nil, _value), do: acc

  defp put_actual(acc, {name, unit, _counter_unit}, value) do
    acc
    |> Map.put(name, value / @units[unit])
    |> Map.put(name <> "unit", unit)
  end

  defp put_counter(acc, nil, _value), do: acc

  defp put_counter(acc, {name, _unit, counter_unit}, value) do
    acc
    |> Map.put(name <> "counter", value / @units[counter_unit])
    |> Map.put(name <> "counterunit", counter_unit)
  end

  defp put_version(acc, nil, _raw), do: acc

  defp put_version(acc, {name, _unit, _counter_unit}, <<major, minor, patch, revision>>) do
    # major/minor/patch are the raw byte values; `revision` (1..6) selects a
    # release-type suffix. Upstream intended this mapping (its own chr()-based
    # implementation never actually matched); we apply the intended suffix.
    version = "#{major}.#{minor}.#{patch}" <> Map.get(@version_suffix, revision, "")
    Map.put(acc, name, version)
  end
end
