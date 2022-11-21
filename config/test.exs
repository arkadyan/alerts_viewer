import Config

# Don't run data processes (e.g. the API stream) during test
config :alerts_viewer, start_data_processes: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :alerts_viewer, AlertsViewerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "fs0gZF8ZwggDlJ0s/uYfI5v9oEoqJUUnaqG3WmkBOWxeqRTd7hi/76bo8/20qT2D",
  server: false

# In test we don't send emails.
config :alerts_viewer, AlertsViewer.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
