defmodule SmaLix.Application do
  @moduledoc """
  OTP application and root supervisor for SmaLix.

  Boot order matters: the pub/sub `Registry`, the `SmaLix.SensorRegistry` and
  the `SmaLix.Store` must be available before any plugin starts, since sources
  register sensors and write to the store, and sinks subscribe to it. Sources
  and sinks each live under their own `SmaLix.PluginSupervisor` so the two
  categories are isolated from each other's failures.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    sources = Application.get_env(:sma_lix, :sources, [])
    sinks = Application.get_env(:sma_lix, :sinks, [])

    Logger.info("Starting SmaLix #{version()}")

    children = [
      {Registry, keys: :duplicate, name: SmaLix.PubSub},
      SmaLix.SensorRegistry,
      SmaLix.Store,
      Supervisor.child_spec(
        {SmaLix.PluginSupervisor, name: SmaLix.Sources.Supervisor, plugins: sources},
        id: SmaLix.Sources.Supervisor
      ),
      Supervisor.child_spec(
        {SmaLix.PluginSupervisor, name: SmaLix.Sinks.Supervisor, plugins: sinks},
        id: SmaLix.Sinks.Supervisor
      )
    ]

    opts = [strategy: :one_for_one, name: SmaLix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc "The running application version."
  @spec version() :: String.t()
  def version do
    case :application.get_key(:sma_lix, :vsn) do
      {:ok, vsn} -> List.to_string(vsn)
      _ -> "unknown"
    end
  end
end
