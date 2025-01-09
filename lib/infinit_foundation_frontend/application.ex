defmodule InfinitFoundationFrontend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      InfinitFoundationFrontendWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:infinit_foundation_frontend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: InfinitFoundationFrontend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: InfinitFoundationFrontend.Finch},
      # Start a worker by calling: InfinitFoundationFrontend.Worker.start_link(arg)
      # {InfinitFoundationFrontend.Worker, arg},
      # Start to serve requests, typically the last entry
      InfinitFoundationFrontendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InfinitFoundationFrontend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InfinitFoundationFrontendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
