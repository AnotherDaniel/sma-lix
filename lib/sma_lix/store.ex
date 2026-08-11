defmodule SmaLix.Store do
  @moduledoc """
  The central shared state for SmaLix — the Elixir counterpart of SMAHub's
  `SMA_Dict`.

  Sources write key/value pairs with `put/2`; sinks read snapshots with
  `get_all/0` and/or subscribe to change notifications with `subscribe/0`.

  Where the Python original combined a plain `dict`, a `threading.Lock` and a
  hand-rolled callback list, this uses the tools the BEAM gives us for free:

    * an **ETS table** for the data, giving lock-free concurrent reads straight
      from the caller process (no GenServer round-trip on the hot read path);
    * a **GenServer** that serialises writes so the "only store/notify when the
      value actually changed" dedup logic is race-free;
    * a **`Registry`** (`SmaLix.PubSub`, started by the application) for
      change notifications, replacing the manual callback list.

  Keys are strings (e.g. `"SHM2.1234.p.pconsume"`). Values are arbitrary terms;
  measurements with a unit are stored as `{value, unit}` tuples, mirroring
  upstream.
  """

  use GenServer

  @table __MODULE__
  @topic :updates

  # ── Public API ─────────────────────────────────────────────────────────────

  @doc "Starts the store. Accepts standard GenServer options (e.g. `:name`)."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Stores `value` under `key`, but only if it differs from the current value.

  Returns `:ok` regardless; when the value actually changed, all subscribers
  receive a `{:sma_update, key, value}` message. This preserves SMAHub's
  `add_item` "set only if changed" semantics.
  """
  @spec put(String.t(), term()) :: :ok
  def put(key, value) when is_binary(key) do
    case lookup(key) do
      {:ok, ^value} -> :ok
      _ -> GenServer.call(__MODULE__, {:put, key, value})
    end
  end

  @doc "Returns the value for `key`, or `default` if absent."
  @spec get(String.t(), term()) :: term()
  def get(key, default \\ nil) do
    case lookup(key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc "Returns a snapshot of the whole store as a map."
  @spec get_all() :: %{optional(String.t()) => term()}
  def get_all do
    @table |> :ets.tab2list() |> Map.new()
  end

  @doc """
  Subscribes the calling process to change notifications.

  The caller will receive `{:sma_update, key, value}` messages whenever a value
  changes. Subscriptions are automatically removed when the process dies.
  """
  @spec subscribe() :: :ok
  def subscribe do
    {:ok, _} = Registry.register(SmaLix.PubSub, @topic, nil)
    :ok
  end

  @doc "Unsubscribes the calling process from change notifications."
  @spec unsubscribe() :: :ok
  def unsubscribe do
    Registry.unregister(SmaLix.PubSub, @topic)
  end

  # ── Server ─────────────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    table =
      :ets.new(@table, [
        :named_table,
        :set,
        :protected,
        read_concurrency: true
      ])

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    # Re-check under the serialised writer to avoid a lost-update race between
    # the optimistic read in `put/2` and here.
    changed? =
      case :ets.lookup(@table, key) do
        [{^key, ^value}] -> false
        _ -> true
      end

    if changed? do
      :ets.insert(@table, {key, value})
      broadcast(key, value)
    end

    {:reply, :ok, state}
  end

  # ── Internals ──────────────────────────────────────────────────────────────

  defp lookup(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :error
    end
  end

  defp broadcast(key, value) do
    Registry.dispatch(SmaLix.PubSub, @topic, fn subscribers ->
      for {pid, _} <- subscribers, do: send(pid, {:sma_update, key, value})
    end)
  end
end
