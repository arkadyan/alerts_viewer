defmodule AlertsViewerWeb.Router do
  use AlertsViewerWeb, :router

  pipeline :get_flags do
    plug AlertsViewerWeb.Plug.PutFlagsInSessionPlug
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:get_flags)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {AlertsViewerWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AlertsViewerWeb do
    get("/_health", HealthController, :index)
  end

  scope "/_flags", Laboratory do
    pipe_through(:browser)
    forward "/", Router
  end

  live_session :default, on_mount: AlertsViewerWeb.PutFlagsInAssignsHook do
    scope "/", AlertsViewerWeb do
      pipe_through(:browser)

      get("/", PageController, :home)

      live("/alerts", AlertsLive, :index)
      live("/alerts/:id", AlertsLive, :show)

      live("/bus", BusLive)
      live("/alerts-to-close", AlertsToCloseLive)
      live("/open-delay-alerts", OpenDelayAlertsLive)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AlertsViewerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:alerts_viewer, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: AlertsViewerWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
