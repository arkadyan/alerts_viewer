# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :alerts_viewer,
  # Default. Can be configured via environment variable, which is loaded in application.ex
  api_url: {:system, "API_URL"},
  api_key: {:system, "API_KEY"},
  api_cache_size: 10_000,
  delay_alert_algorithm_components: [
    AlertsViewer.DelayAlertAlgorithm.MedianAdherenceComponent,
    AlertsViewer.DelayAlertAlgorithm.StandardDeviationAdherenceComponent,
    AlertsViewer.DelayAlertAlgorithm.MedianAndStandardDeviationAdherenceComponent,
    AlertsViewer.DelayAlertAlgorithm.MedianInstantaneousHeadwayComponent,
    AlertsViewer.DelayAlertAlgorithm.StandardDeviationInstantaneousHeadwayComponent,
    AlertsViewer.DelayAlertAlgorithm.MedianHeadwayDeviationComponent,
    AlertsViewer.DelayAlertAlgorithm.StandardDeviationHeadwayDeviationComponent,
    AlertsViewer.DelayAlertAlgorithm.MaxAdherenceComponent,
    AlertsViewer.DelayAlertAlgorithm.MaxHeadwayDeviationComponent
  ],
  swiftly_authorization_key: {:system, "SWIFTLY_AUTHORIZATION_KEY"},
  swiftly_realtime_vehicles_url: {:system, "SWIFTLY_REALTIME_VEHICLES_URL"},
  start_data_processes: true,
  stop_recommendation_algorithm_components: [
    AlertsViewer.StopRecommendationAlgorithm.AlertDurationComponent,
    AlertsViewer.StopRecommendationAlgorithm.MedianHeadwayDeviationDiffComponent,
    AlertsViewer.StopRecommendationAlgorithm.MedianAdherenceComponent,
    AlertsViewer.StopRecommendationAlgorithm.HeadwayDeviationComponent,
    AlertsViewer.StopRecommendationAlgorithm.AdherenceComponent
  ],
  trip_updates_url: {:system, "TRIP_UPDATES_URL"},
  google_tag_manager_id: {:system, "GOOGLE_TAG_MANAGER_ID"}

# Configures the endpoint
config :alerts_viewer, AlertsViewerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: AlertsViewerWeb.ErrorHTML, json: AlertsViewerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AlertsViewer.PubSub,
  live_view: [signing_salt: "qxJ036Kg"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :alerts_viewer, AlertsViewer.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.1.8",
  default: [
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

config :laboratory,
  features: [
    {:show_internal_pages_flag, "Internal Pages", "Makes links to internal-only pages visible"}
  ],
  cookie: [
    # one month,
    max_age: 3600 * 24 * 30,
    http_only: true
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
