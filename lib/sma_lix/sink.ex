defmodule SmaLix.Sink do
  @moduledoc """
  Behaviour and scaffolding for **sink** plugins — the components that publish
  data collected in `SmaLix.Store` to the outside world (MQTT, files, ...).

  This replaces SMAHub's `execute(config, get_items, register_callback,
  do_stop)` Python contract. Registering a callback becomes subscribing to the
  store; polling `get_items()` becomes an optional periodic `handle_flush/2`.

  ## Writing a sink

      defmodule SmaLix.Sinks.Demo do
        use SmaLix.Sink

        @impl true
        def setup(config), do: {:ok, %{}, config[:interval]}

        # Called on every value change (like a registered callback).
        @impl true
        def handle_update(key, value, state) do
          Logger.debug("\#{key} = \#{inspect(value)}")
          {:ok, state}
        end

        # Called every interval_ms with the full snapshot (like polling get_items).
        @impl true
        def handle_flush(items, state) do
          for {k, v} <- items, do: IO.puts("\#{k}: \#{inspect(v)}")
          {:ok, state}
        end
      end

  ## Callbacks

    * `setup/1` (required) — initialise from config; return `{:ok, state}` or
      `{:ok, state, interval_ms}` to enable periodic flushes; `:disabled` to opt
      out; `{:error, reason}` to fail startup.
    * `handle_update/3` (optional) — a value changed; publish on change.
    * `handle_flush/2` (optional) — periodic full snapshot republish.
    * `handle_message/2` (optional) — arbitrary process messages.
  """

  @type state :: term()
  @type ok :: {:ok, state()} | {:stop, term(), state()}

  @callback setup(config :: keyword()) ::
              {:ok, state()}
              | {:ok, state(), interval_ms :: non_neg_integer()}
              | :disabled
              | {:error, term()}
  @callback handle_update(key :: String.t(), value :: term(), state()) :: ok()
  @callback handle_flush(items :: %{optional(String.t()) => term()}, state()) :: ok()
  @callback handle_message(msg :: term(), state()) :: ok()

  @optional_callbacks handle_update: 3, handle_flush: 2, handle_message: 2

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour SmaLix.Sink
      require Logger

      def start_link(_arg \\ []) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      @impl GenServer
      def init(_arg) do
        Logger.metadata(plugin: SmaLix.Plugin.name(__MODULE__))
        config = SmaLix.Config.for_plugin(__MODULE__)

        if SmaLix.Config.enabled?(config) do
          case SmaLix.Sink.run_setup(__MODULE__, config) do
            {:ok, pstate} ->
              SmaLix.Store.subscribe()
              Logger.info("started")
              {:ok, %{plugin: pstate, interval: nil}}

            {:ok, pstate, interval} ->
              SmaLix.Store.subscribe()
              Logger.info("started")
              schedule_flush(interval)
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
      def handle_info({:sma_update, key, value}, %{plugin: pstate} = state) do
        key |> handle_update(value, pstate) |> SmaLix.Sink.apply_result(state)
      end

      def handle_info(:__flush__, %{plugin: pstate, interval: interval} = state) do
        result = SmaLix.Store.get_all() |> handle_flush(pstate)
        schedule_flush(interval)
        SmaLix.Sink.apply_result(result, state)
      end

      def handle_info(msg, %{plugin: pstate} = state) do
        msg |> handle_message(pstate) |> SmaLix.Sink.apply_result(state)
      end

      # Default callback implementations — overridable by the plugin.
      @impl SmaLix.Sink
      def handle_update(_key, _value, state), do: {:ok, state}

      @impl SmaLix.Sink
      def handle_flush(_items, state), do: {:ok, state}

      @impl SmaLix.Sink
      def handle_message(_msg, state), do: {:ok, state}

      defp schedule_flush(nil), do: :ok
      defp schedule_flush(interval), do: Process.send_after(self(), :__flush__, interval)

      defoverridable handle_update: 3, handle_flush: 2, handle_message: 2
    end
  end

  @doc false
  @spec run_setup(module(), keyword()) ::
          {:ok, state()} | {:ok, state(), non_neg_integer()} | :disabled | {:error, term()}
  def run_setup(module, config), do: module.setup(config)

  @doc false
  def apply_result({:ok, pstate}, state), do: {:noreply, %{state | plugin: pstate}}
  def apply_result({:stop, reason, pstate}, state), do: {:stop, reason, %{state | plugin: pstate}}
end
