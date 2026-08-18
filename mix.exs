defmodule SmaLix.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/AnotherDaniel/smahub"

  def project do
    [
      app: :sma_lix,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description:
        "SMA PV data hub — Elixir/OTP port of SMAHub. Collects data from SMA " <>
          "photovoltaic products via source plugins and publishes it via sink plugins.",
      package: package(),
      name: "SmaLix",
      source_url: @source_url,
      docs: [main: "readme", extras: ["README.md", "LICENSE"]],
      dialyzer: [
        # Keep PLTs in a stable, cacheable location for CI.
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SmaLix.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:tortoise311, "~> 0.12"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      # convenience: run the daemon in the foreground
      run: ["run --no-halt"]
    ]
  end

  defp package do
    [
      licenses: ["GPL-2.0-only"],
      links: %{"Upstream (SMAHub)" => @source_url}
    ]
  end
end
