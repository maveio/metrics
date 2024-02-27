defmodule MaveMetrics.Repo.Migrations.AddIndexForDailySessionView do
  use Ecto.Migration

  def change do
    excute("CREATE INDEX ON daily_session_aggregation (video_id, session_date)")
  end
end
