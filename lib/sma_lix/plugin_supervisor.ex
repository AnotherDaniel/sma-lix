defmodule SmaLix.PluginSupervisor do
  @moduledoc """
  A `one_for_one` supervisor for a category of plugins (sources or sinks).

  Each plugin module is started as a child. Plugins that are disabled (or opt
  out via `:disabled`) return `:ignore` from `init/1`, so they occupy a child
  spec but run no process — and a crash in one plugin never takes down its
  siblings.
  """

  use Supervisor

  def start_link(opts) do
    {name, opts} = Keyword.pop!(opts, :name)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    plugins = Keyword.fetch!(opts, :plugins)
    Supervisor.init(plugins, strategy: :one_for_one)
  end
end
