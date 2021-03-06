defmodule TellerApiHttp.MixProject do
  use Mix.Project

  def project do
    [
      app: :teller_api_http,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TellerApiHttp.Application, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.9"},
      {:jason, "~> 1.2"},
      {:cachex, "~> 3.4"},
      {:prometheus, "~> 4.8"},
      {:prometheus_cowboy, "~> 0.1.8"},
      {:teller_api_procgen, in_umbrella: true}
    ]
  end
end
