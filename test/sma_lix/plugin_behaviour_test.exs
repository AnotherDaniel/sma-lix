defmodule SmaLix.PluginBehaviourTest do
  @moduledoc """
  Exercises the `SmaLix.Source` and `SmaLix.Sink` scaffolding using purpose-built
  test plugins, verifying the end-to-end flow: a source emits into the store and
  a subscribed sink observes the change.
  """
  use ExUnit.Case, async: false

  defmodule TestSource do
    use SmaLix.Source

    @impl true
    def setup(config), do: {:ok, %{n: 0}, config[:interval]}

    @impl true
    def poll(%{n: n} = state), do: {:emit, [{"test.source.value", n}], %{state | n: n + 1}}
  end

  defmodule TestSink do
    use SmaLix.Sink

    @impl true
    def setup(config), do: {:ok, %{pid: config[:pid]}}

    @impl true
    def handle_update(key, value, %{pid: pid} = state) do
      send(pid, {:sink_update, key, value})
      {:ok, state}
    end
  end

  test "an interval source emits sequential values into the store" do
    Application.put_env(:sma_lix, TestSource, enabled: true, interval: 20)
    on_exit(fn -> Application.delete_env(:sma_lix, TestSource) end)

    SmaLix.Store.subscribe()
    start_supervised!(TestSource)

    assert_receive {:sma_update, "test.source.value", 0}, 500
    assert_receive {:sma_update, "test.source.value", 1}, 500

    SmaLix.Store.unsubscribe()
  end

  test "a sink receives updates for store changes" do
    Application.put_env(:sma_lix, TestSink, enabled: true, pid: self())
    on_exit(fn -> Application.delete_env(:sma_lix, TestSink) end)

    start_supervised!(TestSink)

    SmaLix.Store.put("sink.test.key", 7)
    assert_receive {:sink_update, "sink.test.key", 7}, 500
  end

  test "a disabled plugin does not start a running process" do
    Application.put_env(:sma_lix, TestSource, enabled: false)
    on_exit(fn -> Application.delete_env(:sma_lix, TestSource) end)

    start_supervised(TestSource)
    assert Process.whereis(TestSource) == nil
  end
end
