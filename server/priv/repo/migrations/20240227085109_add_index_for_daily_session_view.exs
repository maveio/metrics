defmodule MaveMetrics.Repo.Migrations.AddIndexForDailySessionView do
  use Ecto.Migration

  def change do
    execute("CREATE INDEX ON daily_session_aggregation (video_id, session_date)")
  end
end
