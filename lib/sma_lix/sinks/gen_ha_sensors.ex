defmodule SmaLix.Sinks.GenHaSensors do
  @moduledoc """
  Generates Home Assistant MQTT-sensor YAML definitions for all collected data,
  one file per device group. Port of `plugins/sinks/gen_ha_sensors`.

  Runs purely on the periodic flush: every `:generate_freq` seconds it groups
  the store by the leading key segment and writes `<prefix><group>.yaml` files,
  deriving `device_class`/`state_class` from units and key names.
  """

  use SmaLix.Sink
  require Logger

  @impl true
  def setup(config) do
    state = %{
      filename_prefix: Keyword.get(config, :filename_prefix, ""),
      output_dir: Keyword.get(config, :output_dir, "."),
      icons: Keyword.get(config, :icons, %{})
    }

    {:ok, state, Keyword.get(config, :generate_freq, 60) * 1000}
  end

  @impl true
  def handle_flush(items, state) do
    items
    |> Enum.group_by(fn {key, _value} -> group(key) end)
    |> Enum.each(fn {group, group_items} -> write_group(group, group_items, state) end)

    {:ok, state}
  end

  # ── File generation ─────────────────────────────────────────────────────────

  defp write_group(group, group_items, state) do
    path = Path.join(state.output_dir, "#{state.filename_prefix}#{group}.yaml")
    content = Enum.map_join(group_items, fn {key, value} -> entry(key, value, group, state) end)

    case File.write(path, content) do
      :ok -> :ok
      {:error, reason} -> Logger.error("Error writing to file #{path}: #{inspect(reason)}")
    end
  end

  defp entry(key, value, group, state) do
    header =
      "- name: #{String.replace(key, ".", "_")}\n" <>
        "  state_topic: \"#{String.replace(key, ".", "/")}\"\n"

    header <> metadata(key, value, group, state)
  end

  # value carries a unit → emit unit/device_class/state_class
  defp metadata(key, {_value, unit}, _group, _state) do
    line = "  unit_of_measurement: \"#{unit}\"\n"

    case device_class(unit) do
      nil ->
        line

      dev_class ->
        line = line <> "  device_class: \"#{dev_class}\"\n"

        case state_class(key, unit) do
          nil -> line
          stat_class -> line <> "  state_class: \"#{stat_class}\"\n"
        end
    end
  end

  # no unit → use the configured per-group icon, if any
  defp metadata(_key, _value, group, state) do
    case Map.get(state.icons, group) do
      nil -> ""
      icon -> "  icon: \"#{icon}\"\n"
    end
  end

  defp group(key), do: key |> String.split(".", parts: 2) |> List.first()

  # ── Home Assistant class mappings (from smahub gen_ha_sensors.py) ────────────

  # Flat unit → HA device-class lookup mirroring upstream; the complexity check
  # is waived because splitting the table would not improve readability.
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp device_class(unit) do
    case unit do
      u when u in ["Wh", "kWh"] -> "energy"
      u when u in ["VA", "kVA"] -> "apparent_power"
      "var" -> "reactive_power"
      "V" -> "voltage"
      "A" -> "current"
      "Hz" -> "frequency"
      u when u in ["W", "kW"] -> "power"
      "°C" -> "temperature"
      "s" -> "duration"
      _ -> nil
    end
  end

  defp state_class(name, unit) do
    cond do
      String.contains?(name, "WCtlComCfg") -> "total"
      String.contains?(name, "TotWh") or String.contains?(name, "PvWh") -> "total_increasing"
      String.contains?(name, "HealthStt") -> nil
      unit in ["V", "A", "VA", "var", "W", "Hz"] -> "measurement"
      unit in ["Wh", "kWh", "kVAh", "kvarh"] -> "total"
      unit == "s" -> "total_increasing"
      true -> nil
    end
  end
end
