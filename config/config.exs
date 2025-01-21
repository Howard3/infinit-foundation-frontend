# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :infinit_foundation_frontend,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :infinit_foundation_frontend, InfinitFoundationFrontendWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [
      html: InfinitFoundationFrontendWeb.ErrorHTML,
      json: InfinitFoundationFrontendWeb.ErrorJSON
    ],
    layout: false
  ],
  pubsub_server: InfinitFoundationFrontend.PubSub,
  live_view: [signing_salt: "AkMZvhrA"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :infinit_foundation_frontend, InfinitFoundationFrontend.Mailer,
  adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  infinit_foundation_frontend: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  infinit_foundation_frontend: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :infinit_foundation_frontend, :feeding_backend,
    base_url: System.get_env("FEEDING_BACKEND_URL", "http://localhost:3000/api"),
    api_key: System.get_env("FEEDING_BACKEND_API_KEY")

config :infinit_foundation_frontend, InfinitFoundationFrontend.Guardian,
  issuer: System.get_env("CLERK_FRONTEND_API"),
  allowed_algos: ["RS256"],
  verify_issuer: true,
  secret_fetcher: InfinitFoundationFrontend.Guardian.SecretFetcher

config :infinit_foundation_frontend, :clerk,
  frontend_api: System.get_env("CLERK_FRONTEND_API"),
  publishable_key: System.get_env("CLERK_PUBLISHABLE_KEY")

config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET_KEY")

config :infinit_foundation_frontend, :stripe,
  public_key: System.get_env("STRIPE_PUBLIC_KEY"),
  secret_key: System.get_env("STRIPE_SECRET_KEY")
