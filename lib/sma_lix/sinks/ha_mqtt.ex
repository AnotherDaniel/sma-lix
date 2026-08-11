defmodule SmaLix.Sinks.HaMqtt do
  @moduledoc """
  Publishes data to Home Assistant via MQTT autodiscovery. Port of
  `plugins/sinks/ha_mqtt`.

  Where the Python plugin depended on the `ha_mqtt_discoverable` library, this
  implements the (small) discovery protocol directly over `Tortoise311`: for
  each measurement with a registered `SmaLix.Sensor` definition it publishes a
  retained discovery config to `<discovery_prefix>/sensor/<object_id>/config`
  and the value to a matching state topic.

  Discovery configs are published once per sensor (during the periodic sweep);
  value changes thereafter are pushed to the state topic via `handle_update/3`.
  """

  use SmaLix.Sink
  require Logger

  alias SmaLix.{Helpers, Plugin, SensorRegistry}

  @impl true
  def setup(config) do
    client_id = "smahub_ha#{Keyword.get(config, :ident_postfix, "")}"

    connection_opts =
      [
        client_id: client_id,
        server: {Tortoise311.Transport.Tcp, host: config[:address], port: config[:port] || 1883},
        handler: {Tortoise311.Handler.Default, []},
        clean_session: false
      ]
      |> maybe_put(:user_name, config[:username])
      |> maybe_put(:password, config[:password])

    case Tortoise311.Connection.start_link(connection_opts) do
      {:ok, _pid} ->
        state = %{
          client_id: client_id,
          discovery_prefix: Keyword.get(config, :discovery_prefix, "homeassistant"),
          # object_id => %{state_topic: ..., has_unit: boolean}
          announced: %{},
          # group => device block map
          devices: %{}
        }

        {:ok, state, Keyword.get(config, :update_freq, 10) * 1000}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def handle_update(key, value, state) do
    # device info is not published as its own entity
    if String.contains?(key, "device_info") do
      {:ok, state}
    else
      object_id = object_id(key)

      case Map.get(state.announced, object_id) do
        nil ->
          {:ok, state}

        sensor ->
          publish_state(state.client_id, sensor, value)
          {:ok, state}
      end
    end
  end

  @impl true
  def handle_flush(items, state) do
    groups = Enum.group_by(items, fn {key, _v} -> Plugin.group(key) end)

    state =
      Enum.reduce(groups, state, fn {group, group_items}, state ->
        {device, state} = ensure_device(group, group_items, state)

        Enum.reduce(group_items, state, fn {key, value}, state ->
          sweep_sensor(key, value, group, device, state)
        end)
      end)

    {:ok, state}
  end

  # ── Discovery + state publishing ────────────────────────────────────────────

  # One measurement during the periodic sweep: announce it (once) if it has a
  # matching, enabled sensor definition, then publish its current value.
  defp sweep_sensor(key, value, group, device, state) do
    cond do
      String.contains?(key, "device_info") ->
        state

      Map.has_key?(state.announced, object_id(key)) ->
        publish_state(state.client_id, state.announced[object_id(key)], value)
        state

      true ->
        case lookup_sensor(group, key) do
          nil ->
            state

          sensor ->
            entry = announce(sensor, key, device, state)
            publish_state(state.client_id, entry, value)
            %{state | announced: Map.put(state.announced, object_id(key), entry)}
        end
    end
  end

  defp lookup_sensor(group, key) do
    case SensorRegistry.sensor(String.upcase(group), Plugin.sub_key(key)) do
      %SmaLix.Sensor{enabled: true} = sensor -> sensor
      _ -> nil
    end
  end

  # Publishes the retained discovery config and returns the announced-entry we
  # keep to push future state updates.
  defp announce(sensor, key, device, state) do
    object_id = object_id(key)
    state_topic = "#{state.discovery_prefix}/sensor/#{object_id}/state"
    config_topic = "#{state.discovery_prefix}/sensor/#{object_id}/config"

    config =
      %{
        "unique_id" => key,
        "name" => sensor.name || key,
        "state_topic" => state_topic,
        "unit_of_measurement" => sensor.unit_of_measurement,
        "device_class" => sensor.device_class,
        "state_class" => sensor.state_class,
        "entity_category" => sensor.entity_category,
        "suggested_display_precision" => sensor.suggested_display_precision,
        "icon" => sensor.icon,
        "device" => device
      }
      |> drop_nil()

    Tortoise311.publish(state.client_id, config_topic, Jason.encode!(config),
      qos: 0,
      retain: true
    )

    %{state_topic: state_topic, has_unit: sensor.unit_of_measurement != nil}
  end

  defp ensure_device(group, group_items, state) do
    case Map.get(state.devices, group) do
      nil ->
        device = build_device(group_items)
        {device, %{state | devices: Map.put(state.devices, group, device)}}

      device ->
        {device, state}
    end
  end

  defp build_device(group_items) do
    fields =
      for {key, value} <- group_items,
          parts = String.split(key, "."),
          Enum.at(parts, 2) == "device_info",
          into: %{},
          do: {List.last(parts), value}

    %{
      "identifiers" => [to_string(fields["identifiers"])],
      "name" => fields["name"],
      "model" => fields["model"],
      "manufacturer" => fields["manufacturer"],
      "sw_version" => fields["sw_version"]
    }
    |> drop_nil()
  end

  defp publish_state(client_id, %{state_topic: topic, has_unit: has_unit}, value) do
    raw = strip_unit(value)

    payload =
      if not has_unit do
        case Helpers.status_string(raw) do
          "" -> raw
          text -> text
        end
      else
        raw
      end

    Tortoise311.publish(client_id, topic, to_string(payload), qos: 0, retain: true)
  end

  defp strip_unit({value, _unit}), do: value
  defp strip_unit(value), do: value

  # ── Helpers ─────────────────────────────────────────────────────────────────

  defp object_id(key), do: String.replace(key, ".", "_")

  defp drop_nil(map), do: for({k, v} <- map, v != nil, into: %{}, do: {k, v})

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, _key, ""), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
