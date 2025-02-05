defmodule InfinitFoundationFrontend.MixProject do
  use Mix.Project

  def project do
    [
      app: :infinit_foundation_frontend,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {InfinitFoundationFrontend.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      # TODO bump on release to {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_live_view, "~> 1.0.0-rc.1", override: true},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:req, "~> 0.5.0"},
      {:guardian, "~> 2.3"},
      {:jose, "~> 1.11"},
      {:stripity_stripe, "~> 3.0"},
      {:posthog, "~> 0.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind infinit_foundation_frontend", "esbuild infinit_foundation_frontend"],
      "assets.deploy": [
        "tailwind infinit_foundation_frontend --minify",
        "esbuild infinit_foundation_frontend --minify",
        "phx.digest"
      ],
      "fly.staging": [
        "cmd fly deploy --config fly.staging.toml --remote-only"
      ],
      "fly.production": [
        "cmd fly deploy --config fly.production.toml --remote-only"
      ],
      "fly.staging.monitor": [
        "cmd fly deploy --config fly.staging.toml --remote-only",
        "cmd fly status --config fly.staging.toml"
      ],
      "fly.production.monitor": [
        "cmd fly deploy --config fly.production.toml --remote-only",
        "cmd fly status --config fly.production.toml"
      ],
      "fly.staging.console": [
        "cmd fly ssh console --config fly.staging.toml --command '/bin/bash -c \"/app/bin/infinit_foundation_frontend remote\"'"
      ],
      "fly.production.console": [
        "cmd fly ssh console --config fly.production.toml --command '/bin/bash -c \"/app/bin/infinit_foundation_frontend remote\"'"
      ]
    ]
  end
end
