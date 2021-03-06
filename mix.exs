defmodule Eactivitypub.MixProject do
  use Mix.Project

  def project do
    [
      app: :eactivitypub,
      version: "0.2.0",
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [casa: []],
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :plug_cowboy],
      mod: {Eactivitypub, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.3"},
      {:jason, "~> 1.2"},
      {:gen_stage, "~> 1.0"},
      {:rustler, "~> 0.22-rc"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
