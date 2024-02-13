defmodule MaveMetrics.Repo do
  use Ecto.Repo,
    otp_app: :mave_metrics,
    adapter: Ecto.Adapters.Postgres
end
