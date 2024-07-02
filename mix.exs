defmodule Restruct.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/bjyoungblood/restruct"

  def project do
    [
      app: :restruct,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs(),
      preferred_cli_env: [docs: :docs, "hex.publish": :docs]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :docs, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp description() do
    "Ensure structs match their current definition."
  end

  defp docs() do
    [
      main: "Restruct",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
