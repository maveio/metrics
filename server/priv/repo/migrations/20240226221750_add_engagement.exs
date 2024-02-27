defmodule MaveMetrics.Repo.Migrations.AddEngagement do
  use Ecto.Migration

  def change do
    execute("""
    CREATE MATERIALIZED VIEW IF NOT EXISTS video_views_per_second_per_day_aggregate AS
      SELECT
        e.video_id,
        DATE(e.timestamp) AS event_date,
        gs.second AS video_second,
        COUNT(*) AS views
      FROM
        events e
      JOIN
        events e_next ON e.session_id = e_next.session_id
                      AND e_next.type = 'pause'
                      AND e_next.timestamp > e.timestamp
                      AND e.type = 'play',
      LATERAL
        generate_series(
          floor(e.video_time)::int,
          ceil(e_next.video_time)::int - 1
        ) AS gs(second)
      GROUP BY
        e.video_id, DATE(e.timestamp), gs.second;
    """)

    execute("""
    CREATE INDEX ON video_views_per_second_per_day_aggregate (video_id, event_date, video_second);
    """)
  end
end
