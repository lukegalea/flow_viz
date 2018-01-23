defmodule FlowViz.Mixfile do
  use Mix.Project

  def project do
    [
      app: :flow_viz,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "A utility to track and graph throughput in a Flow workflow to help optimize performance",
      package: package(),
      docs: docs()
    ]
  end

  defp package do
    [
      organization: "Precision Nutrition",
      maintainers: ["Luke Galea"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/lukegalea/flow_viz"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flow, "~> 0.11"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [main: "FlowViz"]
  end
end
