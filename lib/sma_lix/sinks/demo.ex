defmodule SmaLix.Sinks.Demo do
  @moduledoc """
  A trivial demonstration sink: logs every value change, and periodically prints
  the full set of collected values. Port of `plugins/sinks/demo`.
  """

  use SmaLix.Sink
  require Logger

  @impl true
  def setup(config) do
    {:ok, %{}, config[:interval]}
  end

  @impl true
  def handle_update(key, value, state) do
    Logger.debug("Key #{key} was updated with value #{inspect(value)}")
    {:ok, state}
  end

  @impl true
  def handle_flush(items, state) do
    IO.puts("Current SMA values:")

    for {key, value} <- items do
      IO.puts("Key: #{key}, Value: #{inspect(value)}")
    end

    {:ok, state}
  end
end
