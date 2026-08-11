defmodule SmaLix.SensorRegistry do
  @moduledoc """
  Registry of Home Assistant sensor definitions, keyed by device group name
  (e.g. `"SHM2"`, `"TRIPOWERX"`).

  This is the Elixir counterpart of SMAHub's `utils/smasensors.py` global
  `SENSOR_REGISTRY` dict. Sources register their definition list on startup;
  discovery-aware sinks look them up. Backed by a `:protected` ETS table owned
  by this process for lock-free concurrent reads.

  Registration is first-write-wins, matching upstream's `register_sensor_dict`.
  """

  use GenServer

  @table __MODULE__

  # ── Public API ─────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers the sensor definitions for a device group, unless already present.

  `device` is the group name (upstream used names like `"SENSORS_SHM2"`; here
  we normalise to the bare group, e.g. `"SHM2"`). `sensors` is a list of
  `SmaLix.Sensor` structs (or attribute maps/keywords, which are coerced).
  """
  @spec register(String.t(), [SmaLix.Sensor.t() | map() | keyword()]) :: :ok
  def register(device, sensors) do
    GenServer.call(__MODULE__, {:register, device, coerce(sensors)})
  end

  @doc "Returns the sensor list for `device`, or `nil` if unknown."
  @spec get(String.t()) :: [SmaLix.Sensor.t()] | nil
  def get(device) do
    case :ets.lookup(@table, device) do
      [{^device, sensors}] -> sensors
      [] -> nil
    end
  end

  @doc "Returns the sensor definition matching `key` within `device`, or nil."
  @spec sensor(String.t(), String.t()) :: SmaLix.Sensor.t() | nil
  def sensor(device, key) do
    with sensors when is_list(sensors) <- get(device) do
      Enum.find(sensors, fn s -> s.key == key end)
    else
      _ -> nil
    end
  end

  @doc """
  Returns the `unit_of_measurement` for `key` within `device`, or `nil`.

  Mirrors upstream `get_parameter_unit`.
  """
  @spec unit(String.t(), String.t()) :: String.t() | nil
  def unit(device, key) do
    case sensor(device, key) do
      %SmaLix.Sensor{unit_of_measurement: unit} -> unit
      _ -> nil
    end
  end

  # ── Server ─────────────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    table = :ets.new(@table, [:named_table, :set, :protected, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:register, device, sensors}, _from, state) do
    # first-write-wins, like upstream register_sensor_dict
    :ets.insert_new(@table, {device, sensors})
    {:reply, :ok, state}
  end

  # ── Internals ──────────────────────────────────────────────────────────────

  defp coerce(sensors) do
    Enum.map(sensors, fn
      %SmaLix.Sensor{} = s -> s
      attrs -> SmaLix.Sensor.new(attrs)
    end)
  end
end
