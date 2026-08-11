defmodule SmaLix.HelpersTest do
  use ExUnit.Case, async: true

  alias SmaLix.Helpers

  test "status_string maps known codes and blanks unknown ones" do
    assert Helpers.status_string(307) == "Ok"
    assert Helpers.status_string(303) == "Off"
    assert Helpers.status_string(999_999) == ""
  end

  test "to_float parses numbers and numeric strings" do
    assert Helpers.to_float(3) == {:ok, 3.0}
    assert Helpers.to_float(2.5) == {:ok, 2.5}
    assert Helpers.to_float("1.25") == {:ok, 1.25}
    assert Helpers.to_float("42") == {:ok, 42.0}
    assert Helpers.to_float("nope") == :error
    assert Helpers.to_float(nil) == :error
  end

  test "float? mirrors isfloat" do
    assert Helpers.float?("3.14")
    refute Helpers.float?("abc")
  end
end
