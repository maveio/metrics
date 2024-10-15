defmodule MaveMetrics.Repo do
  use Appsignal.Ecto.Repo,
    otp_app: :mave_metrics,
    adapter: Ecto.Adapters.Postgres
end
