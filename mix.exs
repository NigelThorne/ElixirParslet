defmodule FizzBuzz.Mixfile do
  use Mix.Project

  def project do
    [
      app: :parslet,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env == :dev,
      deps: deps()
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
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
