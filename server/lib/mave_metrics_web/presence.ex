defmodule MaveMetricsWeb.Presence do
  use Phoenix.Presence,
    otp_app: :mave_metrics,
    pubsub_server: MaveMetrics.PubSub
end
