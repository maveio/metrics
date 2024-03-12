defmodule MaveMetrics.Repo.Migrations.AddCaggView do
  use Ecto.Migration

  import Timescale.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

    create_if_not_exists table(:durations, primary_key: false) do
      add(:session_id, :bigint, null: false, primary_key: true)
      add(:timestamp, :timestamptz, null: false, primary_key: true)
      add(:duration, :float)
      add(:watched_seconds, :int4range)
      add(:uniqueness, :float)

      # de-normalized fields from session
      add(:browser, :browser)
      add(:platform, :platform)
      add(:device, :device)
      add(:uri_host, :text)
      add(:uri_path, :text)

      add(:video_id, references(:videos), null: false)
    end

    create_if_not_exists(unique_index(:durations, [:timestamp, :session_id]))
    create_if_not_exists(index(:durations, [:session_id]))
    create_if_not_exists(index(:durations, [:video_id]))
    create_if_not_exists(index(:durations, [:watched_seconds], using: :gist))

    create_hypertable(:durations, :timestamp)

    enable_hypertable_compression(:durations, segment_by: :video_id)
    add_compression_policy(:durations, "1d")
  end
end
