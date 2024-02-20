defmodule MaveMetrics.Repo.Migrations.Redo do
  use Ecto.Migration

  import Timescale.Migration
  # https://hexdocs.pm/timescale/intro.html#building-a-health-tracker

  def up do
    create_timescaledb_extension()

    create_if_not_exists table(:keys) do
      add(:key, :string, null: false)
      add(:disabled_at, :utc_datetime_usec)

      timestamps()
    end

    create_if_not_exists(index(:keys, [:key]))

    create_if_not_exists table(:videos) do
      add(:metadata, :jsonb, null: false)

      add(:key_id, references(:keys), null: false)

      timestamps()
    end

    create_if_not_exists(index(:videos, [:key_id]))
    create_if_not_exists(index(:videos, [:metadata], using: "GIN"))

    execute("CREATE TYPE platform AS ENUM ('ios', 'android', 'mac', 'windows', 'linux', 'other')")

    execute("CREATE TYPE device AS ENUM ('mobile', 'tablet', 'desktop', 'other')")

    execute(
      "CREATE TYPE browser AS ENUM ('edge', 'ie', 'chrome', 'firefox', 'opera', 'safari', 'brave', 'other')"
    )

    create_if_not_exists table(:sessions, primary_key: false) do
      add(:timestamp, :timestamptz, null: false, primary_key: true)
      add(:id, :bigserial, null: false, primary_key: true)

      add(:browser, :browser)
      add(:platform, :platform)
      add(:device, :device)

      add(:uri_host, :text)
      add(:uri_path, :text)

      add(:video_id, references(:videos), null: false)
    end

    create_if_not_exists(unique_index(:sessions, [:timestamp, :id]))
    create_if_not_exists(index(:sessions, [:video_id]))

    create_hypertable(:sessions, :timestamp)

    execute("CREATE TYPE video_event AS ENUM ('play', 'pause')")

    create_if_not_exists table(:events, primary_key: false) do
      add(:timestamp, :timestamptz, null: false, primary_key: true)

      add(:video_time, :float)

      add(:type, :video_event, null: false)

      # Foreign key constraints referencing a hypertable are not supported:
      # add(:session_id, references(:sessions), null: false)
      add(:session_id, :bigint, null: false, primary_key: true)

      add(:video_id, references(:videos), null: false)
    end

    create_if_not_exists(unique_index(:events, [:timestamp, :session_id]))
    create_if_not_exists(index(:events, [:session_id]))

    create_if_not_exists(index(:events, [:video_id]))

    create_hypertable(:events, :timestamp)

    enable_hypertable_compression(:sessions, segment_by: :video_id)
    add_compression_policy(:sessions, "1d")

    enable_hypertable_compression(:events, segment_by: :video_id)
    add_compression_policy(:events, "1d")

    # https://www.timescale.com/learn/postgresql-materialized-views-and-where-to-find-them
    execute("""
    CREATE MATERIALIZED VIEW IF NOT EXISTS daily_session_aggregation AS
      SELECT
        s.video_id,
        DATE(s.timestamp) AS session_date,
        s.uri_host,
        s.uri_path,
        s.platform,
        s.device,
        s.browser,
        s.id AS session_id,
        SUM(paired_events.diff) AS session_watched_seconds
      FROM
        sessions s
      JOIN
        (SELECT
          e.session_id,
          e.video_time AS play_time,
          MIN(e_next.video_time) AS pause_time,
          MIN(e_next.video_time) - e.video_time AS diff
        FROM
          events e
        JOIN
          events e_next ON e.session_id = e_next.session_id
                        AND e_next.type = 'pause'
                        AND e_next.timestamp > e.timestamp
        WHERE
          e.type = 'play'
        GROUP BY
          e.session_id, e.timestamp, e.video_time) AS paired_events ON s.id = paired_events.session_id
      GROUP BY
        s.video_id, s.id, DATE(s.timestamp), s.uri_host, s.uri_path, s.platform, s.device, s.browser;
    """)
  end

  def down do
    drop_if_exists(table("keys"), mode: :cascade)
    execute("DROP TYPE IF EXISTS platform")
    execute("DROP TYPE IF EXISTS device_type")
    execute("DROP TYPE IF EXISTS browser_type")

    drop_if_exists(table("sessions"), mode: :cascade)

    drop_if_exists(table("events"), mode: :cascade)
    execute("DROP TYPE IF EXISTS video_event")

    execute("SELECT decompress_chunk(i, true) from show_chunks('sessions') i;")
    remove_compression_policy(:sessions, if_exists: true)
    disable_hypertable_compression(:sessions)

    execute("SELECT decompress_chunk(i, true) from show_chunks('events') i;")
    flush()
    remove_compression_policy(:events, if_exists: true)
    disable_hypertable_compression(:events)

    drop_timescaledb_extension()
  end
end
