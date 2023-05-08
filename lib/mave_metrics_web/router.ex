defmodule MaveMetricsWeb.Router do
  use MaveMetricsWeb, :router

  # import MaveMetricsWeb.API.Auth
  import Redirect

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MaveMetricsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", MaveMetricsWeb do
    # pipe_through [:api, :require_api_authentication]
    pipe_through :api

    post "/views", API.ViewsController, :views
    get "/views", API.ViewsController, :get_views
    post "/engagement", API.EngagementController, :engagement
    get "/engagement", API.EngagementController, :get_engagement
    post "/sources", API.SourcesController, :sources
    get "/sources", API.SourcesController, :get_sources
  end

  if Mix.env() not in [:dev, :test] do
    redirect "/", "https://mave.io", :permanent
  end

  scope "/", MaveMetricsWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", MaveMetricsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mave_metrics, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", mave_metrics: MaveMetricsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
