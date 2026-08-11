defmodule SmaLix.Plugin do
  @moduledoc """
  Shared helpers used by the source/sink scaffolding.

  Handles the plugin's short display name and the registration/derivation of
  Home Assistant sensor **group** names. A group name is the uppercased first
  segment of a store key (e.g. `"SHM2.1234.p.pconsume"` → `"SHM2"`), which is
  how discovery-aware sinks locate the sensor definitions a source registered.
  """

  @doc "The short, human-facing name of a plugin module (its last segment)."
  @spec name(module()) :: String.t()
  def name(module) do
    module |> Module.split() |> List.last()
  end

  @doc """
  The sensor group name for a store key or configured prefix.

  Takes the first `.`-delimited segment and upcases it, matching how SMAHub's
  discovery sinks derived `SENSORS_<GROUP>` lookups.
  """
  @spec group(String.t() | nil) :: String.t() | nil
  def group(nil), do: nil

  def group(key) do
    key |> to_string() |> String.split(".", parts: 2) |> List.first() |> String.upcase()
  end

  @doc """
  The sensor sub-key within a group, i.e. the store key with the leading
  `<group>.<serial>.` stripped (upstream `".".join(name.split(".")[2:])`).
  """
  @spec sub_key(String.t()) :: String.t()
  def sub_key(store_key) do
    store_key |> String.split(".") |> Enum.drop(2) |> Enum.join(".")
  end

  @doc """
  Registers a source's sensor definitions (from its `sensors/0` callback) under
  the group derived from its `:sensor_prefix` config. No-op when the source
  declares no sensors.
  """
  @spec register_sensors(module()) :: :ok
  def register_sensors(module) do
    case module.sensors() do
      [] ->
        :ok

      sensors ->
        prefix = SmaLix.Config.get(module, :sensor_prefix, name(module))

        case group(prefix) do
          nil -> :ok
          group -> SmaLix.SensorRegistry.register(group, sensors)
        end
    end
  end
end
