defmodule MaveMetrics.Repo.Migrations.RecreateAggregationView do
  use Ecto.Migration

  def change do
    execute("""
    DROP MATERIALIZED VIEW IF EXISTS video_views_per_second_per_day_aggregate;
    """)
  end
end
