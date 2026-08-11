defmodule SmaLix.SpeedwireTest do
  use ExUnit.Case, async: true

  # Builds a minimal but structurally valid Speedwire datagram carrying one
  # "actual" and one "counter" reading for channel 1 (pconsume / W, kWh).
  defp datagram do
    header = "SMA" <> <<0::size(72)>>
    # raw data length 32 -> decoder computes 32 + 16 = 48 (total datagram size)
    length = <<32::16>>
    filler2 = <<0::16>>
    protocol = <<0x6069::16>>
    serial = <<1_234_567_890::32>>
    timestamp = <<0::32>>

    # channel 1, type 4 (actual): 2500 / 10 (W) = 250.0
    actual = <<1::16, 4, 0, 2500::32>>
    # channel 1, type 8 (counter): 3_600_000 / 3_600_000 (kWh) = 1.0
    counter = <<1::16, 8, 0, 3_600_000::64>>

    header <> length <> filler2 <> protocol <> filler2 <> serial <> timestamp <> actual <> counter
  end

  test "decodes header, serial and protocol" do
    emdata = SmaLix.Speedwire.decode(datagram())
    assert emdata["serial"] == 1_234_567_890
    assert emdata["protocol"] == 0x6069
  end

  test "decodes actual measurements with scaling and unit" do
    emdata = SmaLix.Speedwire.decode(datagram())
    assert emdata["pconsume"] == 250.0
    assert emdata["pconsumeunit"] == "W"
  end

  test "decodes counter measurements with scaling and unit" do
    emdata = SmaLix.Speedwire.decode(datagram())
    assert emdata["pconsumecounter"] == 1.0
    assert emdata["pconsumecounterunit"] == "kWh"
  end

  test "returns an empty map for non-SMA datagrams" do
    assert SmaLix.Speedwire.decode(<<"XYZ", 0, 1, 2, 3>>) == %{}
  end
end
