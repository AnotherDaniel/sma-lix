defmodule SmaLix.Sources.EvCharger do
  @moduledoc """
  Source for the SMA EV Charger, via its built-in HTTP/JSON API. Port of
  `plugins/sources/EVCharger`. Shares its collection logic with
  `SmaLix.Sources.SmaHttpApi`.
  """

  use SmaLix.Source
  alias SmaLix.Sources.SmaHttpApi

  @impl true
  defdelegate setup(config), to: SmaHttpApi

  @impl true
  defdelegate poll(state), to: SmaHttpApi

  @impl true
  def sensors, do: SmaLix.Sources.EvCharger.Sensors.list()
end
