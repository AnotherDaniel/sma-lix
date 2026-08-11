defmodule SmaLix.Config do
  @moduledoc """
  Small helpers for reading per-plugin configuration.

  Each plugin's configuration lives under its own module key in the application
  environment (see `config/config.exs` and `config/runtime.exs`), e.g.

      config :sma_lix, SmaLix.Sources.SHM2, enabled: true, update_freq: 2

  This module just provides typed access to that keyword list.
  """

  @doc "Returns the full configuration keyword list for `plugin`."
  @spec for_plugin(module()) :: keyword()
  def for_plugin(plugin) do
    Application.get_env(:sma_lix, plugin, [])
  end

  @doc "Fetches `key` from `plugin`'s configuration, with an optional default."
  @spec get(module(), atom(), term()) :: term()
  def get(plugin, key, default \\ nil) do
    plugin |> for_plugin() |> Keyword.get(key, default)
  end

  @doc "Whether the given resolved config (or plugin module) is enabled."
  @spec enabled?(keyword() | module()) :: boolean()
  def enabled?(config) when is_list(config), do: Keyword.get(config, :enabled, false) == true
  def enabled?(plugin) when is_atom(plugin), do: enabled?(for_plugin(plugin))
end
