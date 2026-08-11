defmodule SmaLix.Source do
  @moduledoc """
  Behaviour and scaffolding for **source** plugins — the components that collect
  data from SMA devices and feed it into `SmaLix.Store`.

  This replaces SMAHub's dir-scanned `execute(config, add_data, dostop)` Python
  contract with a compiled behaviour backed by a supervised `GenServer`. The
  `dostop()` polling flag is gone entirely: stopping is just OTP shutdown.

  ## Writing a source

      defmodule SmaLix.Sources.Demo do
        use SmaLix.Source

        @impl true
        def setup(config) do
          # return {:ok, state} for an event-driven source, or
          # {:ok, state, interval_ms} to have `poll/1` called periodically.
          {:ok, %{i: 1}, config[:interval]}
        end

        @impl true
        def poll(%{i: i} = state) do
          {:emit, [{"demoValue", i}], %{state | i: i + 1}}
        end
      end

  ## Callbacks

    * `setup/1` (required) — initialise from config; return `:disabled` to opt
      out cleanly, or `{:error, reason}` to fail startup.
    * `poll/1` (optional) — invoked every `interval_ms` when `setup/1` requested
      an interval. Return `{:emit, pairs, state}`, `{:noreply, state}` or
      `{:stop, reason, state}`.
    * `handle_message/2` (optional) — handle arbitrary process messages (e.g.
      `{:udp, ...}` for the Speedwire source). Same return shapes as `poll/1`.
    * `sensors/0` (optional) — Home Assistant sensor definitions to register.

  Inside a source, use `put/2` (imported from `SmaLix.Store`) or return
  `{:emit, pairs, state}` to publish data.
  """

  @type state :: term()
  @type pair :: {String.t(), term()}
  @type result ::
          {:noreply, state()}
          | {:emit, [pair()], state()}
          | {:stop, term(), state()}

  @callback setup(config :: keyword()) ::
              {:ok, state()}
              | {:ok, state(), interval_ms :: non_neg_integer()}
              | :disabled
              | {:error, term()}
  @callback poll(state()) :: result()
  @callback handle_message(msg :: term(), state()) :: result()
  @callback sensors() :: [SmaLix.Sensor.t() | map() | keyword()]

  @optional_callbacks poll: 1, handle_message: 2, sensors: 0

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour SmaLix.Source
      require Logger
      import SmaLix.Store, only: [put: 2]

      def start_link(_arg \\ []) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      @impl GenServer
      def init(_arg) do
        Logger.metadata(plugin: SmaLix.Plugin.name(__MODULE__))
        config = SmaLix.Config.for_plugin(__MODULE__)

        if SmaLix.Config.enabled?(config) do
          SmaLix.Plugin.register_sensors(__MODULE__)

          case SmaLix.Source.run_setup(__MODULE__, config) do
            {:ok, pstate} ->
              Logger.info("started")
              {:ok, %{plugin: pstate, interval: nil}}

            {:ok, pstate, interval} ->
              Logger.info("started")
              send(self(), :__poll__)
              {:ok, %{plugin: pstate, interval: interval}}

            :disabled ->
              :ignore

            {:error, reason} ->
              {:stop, reason}
          end
        else
          Logger.info("disabled")
          :ignore
        end
      end

      @impl GenServer
      def handle_info(:__poll__, %{plugin: pstate} = state) do
        pstate |> poll() |> SmaLix.Source.apply_result(state, &schedule_poll/1)
      end

      def handle_info(msg, %{plugin: pstate} = state) do
        msg |> handle_message(pstate) |> SmaLix.Source.apply_result(state, & &1)
      end

      # Default callback implementations — overridable by the plugin.
      @impl SmaLix.Source
      def poll(state), do: {:noreply, state}

      @impl SmaLix.Source
      def handle_message(_msg, state), do: {:noreply, state}

      @impl SmaLix.Source
      def sensors, do: []

      defp schedule_poll(%{interval: nil} = state), do: state

      defp schedule_poll(%{interval: interval} = state) do
        Process.send_after(self(), :__poll__, interval)
        state
      end

      defoverridable poll: 1, handle_message: 2, sensors: 0
    end
  end

  @type setup_result ::
          {:ok, state()} | {:ok, state(), non_neg_integer()} | :disabled | {:error, term()}

  @doc false
  # Indirection with a broad spec so the compiler's type inference does not
  # narrow a plugin's concrete `setup/1` return and flag the generic `init/1`
  # branches as "unmatchable".
  @spec run_setup(module(), keyword()) :: setup_result()
  def run_setup(module, config), do: module.setup(config)

  @doc false
  # Interprets a source callback result and folds it into the GenServer state.
  # `after_fun` lets `poll/1` reschedule itself while message handling does not.
  def apply_result(result, state, after_fun) do
    case result do
      {:noreply, pstate} ->
        {:noreply, after_fun.(%{state | plugin: pstate})}

      {:emit, pairs, pstate} ->
        emit_all(pairs)
        {:noreply, after_fun.(%{state | plugin: pstate})}

      {:stop, reason, pstate} ->
        {:stop, reason, %{state | plugin: pstate}}
    end
  end

  defp emit_all(pairs) do
    Enum.each(pairs, fn {key, value} -> SmaLix.Store.put(key, value) end)
  end
end
