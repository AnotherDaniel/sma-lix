defmodule SmaLix.StoreTest do
  @moduledoc """
  Ports the intent of SMAHub's `tests/test_smadict.py`: the shared store holds
  values, deduplicates unchanged writes, and notifies subscribers on change.
  """
  use ExUnit.Case, async: false

  test "stores and retrieves values" do
    key = unique("alpha")
    assert SmaLix.Store.get(key) == nil
    assert :ok = SmaLix.Store.put(key, 42)
    assert SmaLix.Store.get(key) == 42
  end

  test "get returns the provided default when absent" do
    assert SmaLix.Store.get(unique("missing"), :default) == :default
  end

  test "get_all returns a snapshot map including written keys" do
    key = unique("beta")
    SmaLix.Store.put(key, {123, "W"})
    assert %{^key => {123, "W"}} = SmaLix.Store.get_all()
  end

  test "subscribers are notified only when the value actually changes" do
    key = unique("gamma")
    :ok = SmaLix.Store.subscribe()

    SmaLix.Store.put(key, 1)
    assert_receive {:sma_update, ^key, 1}

    # identical value: no notification (dedup)
    SmaLix.Store.put(key, 1)
    refute_receive {:sma_update, ^key, 1}, 100

    # changed value: notification
    SmaLix.Store.put(key, 2)
    assert_receive {:sma_update, ^key, 2}

    SmaLix.Store.unsubscribe()
  end

  test "unsubscribed processes stop receiving notifications" do
    key = unique("delta")
    :ok = SmaLix.Store.subscribe()
    :ok = SmaLix.Store.unsubscribe()
    SmaLix.Store.put(key, 99)
    refute_receive {:sma_update, ^key, 99}, 100
  end

  defp unique(prefix), do: "#{prefix}.#{System.unique_integer([:positive])}"
end
