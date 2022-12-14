import Config

# Don't run data processes (e.g. the API stream) during test
config :alerts_viewer, start_data_processes: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :alerts_viewer, AlertsViewerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "EGtX7cPHzEq55Ehm/taddWG81PKxrnRbTK+UI6ebiUFcJqqfGiVSU2l0Gesuy7TC",
  server: false

# In test we don't send emails.
config :alerts_viewer, AlertsViewer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
