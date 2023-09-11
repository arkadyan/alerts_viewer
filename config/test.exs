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

config :exvcr,
  vcr_cassette_library_dir: "test/support/fixtures/vcr_cassettes",
  custom_cassette_library_dir: "test/support/fixtures/custom_cassettes",
  filter_request_headers: ["x-api-key"]

config :laboratory,
  features: [
    {:test_flag, "Cool Bean", "cool bean for test"},
    {:show_internal_pages_flag, "Internal Pages", "Makes links to internal-only pages visible"}
  ],
  cookie: [
    # one month,
    max_age: 3600 * 24 * 30,
    http_only: true
  ]
