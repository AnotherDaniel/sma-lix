defmodule SmaLix.Sensor do
  @moduledoc """
  A Home Assistant MQTT-autodiscovery sensor definition.

  Sources describe the sensors they emit (see `c:SmaLix.Source.sensors/0`), and
  discovery-aware sinks (`SmaLix.Sinks.HaMqtt`, `SmaLix.Sinks.GenHaSensors`)
  consult these definitions to publish rich Home Assistant metadata.

  This is the typed replacement for the loose dicts SMAHub kept in
  `SENSORS_*` module-level lists.
  """

  @enforce_keys [:key]
  defstruct key: nil,
            name: nil,
            enabled: true,
            entity_category: nil,
            device_class: nil,
            state_class: nil,
            unit_of_measurement: nil,
            suggested_display_precision: nil,
            icon: nil

  @type t :: %__MODULE__{
          key: String.t(),
          name: String.t() | nil,
          enabled: boolean(),
          entity_category: String.t() | nil,
          device_class: String.t() | nil,
          state_class: String.t() | nil,
          unit_of_measurement: String.t() | nil,
          suggested_display_precision: non_neg_integer() | nil,
          icon: String.t() | nil
        }

  @doc "Builds a sensor definition from a keyword list or map of attributes."
  @spec new(Enumerable.t()) :: t()
  def new(attrs), do: struct!(__MODULE__, attrs)
end
