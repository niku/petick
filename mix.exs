defmodule Petick.MixProject do
  use Mix.Project

  def project do
    [
      app: :petick,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Petick.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:dialyxir, "~> 0.3", only: [:dev]}
    ]
  end

  defp description, do: "Periodic timer"

  defp package do
    [
      maintainers: ["niku"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/niku/petick"}
    ]
  end
end
