defmodule TellerApi.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        teller_api: [
          version: "0.1",
          include_erts: true,
          applications: [
            logger: :permanent,
            decimal: :permanent,
            teller_api_procgen: :permanent,
            teller_api_http: :permanent
          ]
        ]
      ]
    ]
  end

  defp deps do
    []
  end
end
