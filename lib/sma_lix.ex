defmodule SmaLix do
  @moduledoc """
  SmaLix — an Elixir/OTP port of [SMAHub](https://github.com/AnotherDaniel/smahub).

  SmaLix collects data from SMA photovoltaic products (inverters, energy meters)
  via **source** plugins and publishes it to output channels (MQTT, Home
  Assistant, files) via **sink** plugins. All data flows through a central
  `SmaLix.Store`; sinks react to changes via pub/sub and/or periodic snapshots.

  See `SmaLix.Source` and `SmaLix.Sink` for the plugin behaviours, and the
  `SmaLix.Sources.*` / `SmaLix.Sinks.*` modules for the bundled plugins.

  Licensed GPL-2.0, following upstream. Adapted from work by littleyoda
  (Home-Assistant-Tripower-X-MQTT) and datenschuft (SMA-EM).
  """

  @doc "Returns a snapshot of all collected data. See `SmaLix.Store.get_all/0`."
  defdelegate snapshot(), to: SmaLix.Store, as: :get_all
end
