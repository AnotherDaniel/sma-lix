defmodule SmaLix.Helpers do
  @moduledoc """
  Miscellaneous helpers, ported from SMAHub's `utils/smahelpers.py`.

  Includes the TripowerX status-code lookup table and numeric coercion helpers.
  """

  # Lookup for various status texts used by TripowerX inverter parameters.
  # Adapted from https://github.com/littleyoda/Home-Assistant-Tripower-X-MQTT.
  @tripower_status %{
    302 => "---",
    937 => "---",
    973 => "---",
    303 => "Off",
    307 => "Ok",
    311 => "Open",
    3366 => "No scan completed",
    1130 => "No",
    1295 => "Standby",
    295 => "MPP",
    569 => "Activated",
    1779 => "Separated",
    1780 => "Public electricity mains",
    27 => "Special setting",
    51 => "Closed",
    884 => "not active",
    1440 => "Grid mode",
    1042 => "Underexcited",
    4570 => "Wait for enable operation",
    16_777_213 => "Information not available"
  }

  @doc """
  Returns the human-readable status string for a TripowerX status `id`, or an
  empty string if unknown. Mirrors upstream `status_string`.
  """
  @spec status_string(term()) :: String.t()
  def status_string(id) when is_map_key(@tripower_status, id), do: @tripower_status[id]
  def status_string(_id), do: ""

  @doc "The full TripowerX status-code lookup table."
  @spec tripower_status_table() :: %{integer() => String.t()}
  def tripower_status_table, do: @tripower_status

  @doc """
  Parses `value` into a float, returning `{:ok, float}` or `:error`.

  Accepts numbers and numeric strings. Replacement for upstream `isfloat` +
  `float()` used together.
  """
  @spec to_float(term()) :: {:ok, float()} | :error
  def to_float(value) when is_float(value), do: {:ok, value}
  def to_float(value) when is_integer(value), do: {:ok, value * 1.0}

  def to_float(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      # trailing non-numeric characters mean it is not a plain float, matching
      # Python's float() which would raise a ValueError.
      {f, ""} -> {:ok, f}
      _ -> :error
    end
  end

  def to_float(_value), do: :error

  @doc "Whether `value` can be interpreted as a float. Mirrors upstream `isfloat`."
  @spec float?(term()) :: boolean()
  def float?(value), do: match?({:ok, _}, to_float(value))
end
