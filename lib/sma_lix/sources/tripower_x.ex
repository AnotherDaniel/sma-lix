defmodule SmaLix.Sources.TripowerX do
  @moduledoc """
  Source for SMA Tripower X inverters, via the inverter's built-in HTTP/JSON
  API. Port of `plugins/sources/TripowerX`. Shares its collection logic with
  `SmaLix.Sources.SmaHttpApi`.
  """

  use SmaLix.Source
  alias SmaLix.Sources.SmaHttpApi

  @impl true
  defdelegate setup(config), to: SmaHttpApi

  @impl true
  defdelegate poll(state), to: SmaHttpApi

  @impl true
  def sensors, do: SmaLix.Sources.TripowerX.Sensors.list()
end
