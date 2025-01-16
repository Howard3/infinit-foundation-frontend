defmodule InfinitFoundationFrontendWeb.Router do
  use InfinitFoundationFrontendWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {InfinitFoundationFrontendWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InfinitFoundationFrontendWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/sign-in", AuthController, :sign_in
    get "/sign-up", AuthController, :sign_up

    live "/students", StudentLive.Index, :index
    live "/how-it-works", HowItWorksLive, :index
    live "/mission", MissionLive, :index
    live "/impact", ImpactLive, :index
    get "/sign-in-callback", AuthController, :sign_in_callback

    # Add this new route to handle image proxying
    get "/student/profile/photo/*path", ImageController, :proxy_photo
  end

  # Other scopes may use custom stacks.
  # scope "/api", InfinitFoundationFrontendWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:infinit_foundation_frontend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InfinitFoundationFrontendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
