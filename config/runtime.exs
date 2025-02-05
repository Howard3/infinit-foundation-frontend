import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/infinit_foundation_frontend start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :infinit_foundation_frontend, InfinitFoundationFrontendWeb.Endpoint, server: true
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

    signing_salt =
      System.get_env("SESSION_SIGNING_SALT") ||
        raise """
        environment variable SESSION_SIGNING_SALT is missing.
        You can generate one by calling: mix phx.gen.secret
        """
  host = System.get_env("PHX_HOST") || raise("PHX_HOST is not set")
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :infinit_foundation_frontend, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :infinit_foundation_frontend, InfinitFoundationFrontendWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    session_options: [
      store: :cookie,
      key: "_infinit_foundation_frontend_key",
      signing_salt: signing_salt,
      same_site: "Lax"
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :infinit_foundation_frontend, InfinitFoundationFrontendWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :infinit_foundation_frontend, InfinitFoundationFrontendWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :infinit_foundation_frontend, InfinitFoundationFrontend.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

end

config :infinit_foundation_frontend, :feeding_backend,
    base_url: System.get_env("FEEDING_BACKEND_URL") || raise("FEEDING_BACKEND_URL is not set"),
    api_key: System.get_env("FEEDING_BACKEND_API_KEY") || raise("FEEDING_BACKEND_API_KEY is not set")

config :infinit_foundation_frontend, InfinitFoundationFrontend.Guardian,
  issuer: System.get_env("CLERK_FRONTEND_API") || raise("CLERK_FRONTEND_API is not set"),
  allowed_algos: ["RS256"],
  verify_issuer: true,
  secret_fetcher: InfinitFoundationFrontend.Guardian.SecretFetcher

config :infinit_foundation_frontend, :clerk,
  frontend_api: System.get_env("CLERK_FRONTEND_API") || raise("CLERK_FRONTEND_API is not set"),
  publishable_key: System.get_env("CLERK_PUBLISHABLE_KEY") || raise("CLERK_PUBLISHABLE_KEY is not set")

config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET_KEY") || raise("STRIPE_SECRET_KEY is not set")

config :infinit_foundation_frontend, :stripe,
  public_key: System.get_env("STRIPE_PUBLIC_KEY") || raise("STRIPE_PUBLIC_KEY is not set"),
  secret_key: System.get_env("STRIPE_SECRET_KEY") || raise("STRIPE_SECRET_KEY is not set")
