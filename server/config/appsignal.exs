import Config

config :appsignal, :config,
  otp_app: :mave_metrics,
  name: "mave_metrics",
  push_api_key: System.get_env("APPSIGNAL_PUSH_API_KEY"),
  env: Mix.env()
