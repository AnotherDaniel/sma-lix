defmodule SmaLix.Sources.Demo do
  @moduledoc """
  A trivial demonstration source: emits an incrementing `"demoValue"` every
  interval and logs a configurable message. Port of `plugins/sources/demo`.
  """

  use SmaLix.Source
  require Logger

  @impl true
  def setup(config) do
    {:ok, %{i: 1, message: Keyword.get(config, :message, "Hello, world!")}, config[:interval]}
  end

  @impl true
  def poll(%{i: i, message: message} = state) do
    Logger.debug(message)
    {:emit, [{"demoValue", i}], %{state | i: i + 1}}
  end

  @impl true
  def sensors do
    [
      %{key: "demoValue", name: "Demo value", entity_category: "diagnostic"}
    ]
  end
end
