# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mave_metrics,
  ecto_repos: [MaveMetrics.Repo],
  api_auth: System.get_env("METRICS_AUTH_ENABLED") == "true" || false,
  api_user: System.get_env("METRICS_USER"),
  api_password: System.get_env("METRICS_PASSWORD"),
  batch_size: 2

config :mave_metrics, MaveMetrics.Repo, migration_timestamps: [type: :utc_datetime_usec]

config :mave_metrics, MaveMetrics.PartitionedCache,
  gc_interval: :timer.hours(12),
  backend: :shards,
  partitions: 2

# Configures the endpoint
config :mave_metrics, MaveMetricsWeb.Endpoint,
  url: [host: "localhost"],
  check_origin: false,
  render_errors: [
    formats: [html: MaveMetricsWeb.ErrorHTML, json: MaveMetricsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MaveMetrics.PubSub,
  live_view: [signing_salt: "HmL5BxBt"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mave_metrics, MaveMetrics.Mailer, adapter: Swoosh.Adapters.Local

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
  version: "3.2.4",
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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
