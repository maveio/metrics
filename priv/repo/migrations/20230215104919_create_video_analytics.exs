defmodule MaveMetrics.Repo.Migrations.CreateVideoAnalytics do
  use Ecto.Migration

  import Timescale.Migration

  def up do
    create_timescaledb_extension()

    create_if_not_exists table(:videos) do
      add :identifier, :string, null: false
      add :source_uri, :map, null: false

      add :metadata, :jsonb

      timestamps()
    end

    create_if_not_exists unique_index(:videos, [:identifier, :source_uri, :metadata])
    create_if_not_exists index(:videos, [:identifier, :source_uri])
    create_if_not_exists index(:videos, [:metadata], using: "GIN")

    execute "CREATE TYPE platform AS ENUM ('ios', 'android', 'mac', 'windows', 'linux', 'other')"
    execute "CREATE TYPE device_type AS ENUM ('mobile', 'tablet', 'desktop', 'other')"
    execute "CREATE TYPE browser_type AS ENUM ('edge', 'ie', 'chrome', 'firefox', 'opera', 'safari', 'brave', 'other')"

    create_if_not_exists table(:sessions) do
      add :browser_type, :browser_type
      add :platform, :platform
      add :device_type, :device_type

      add :metadata, :jsonb

      add :video_id, references(:videos), null: false

      timestamps()
    end

    create_if_not_exists index(:sessions, [:video_id])
    create_if_not_exists index(:sessions, [:metadata], using: "GIN")
  end

  def down do
    drop table("sessions"), mode: :cascade
    drop table("videos"), mode: :cascade

    drop_timescaledb_extension()
  end
end
