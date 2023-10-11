defmodule MaveMetrics.Repo.Migrations.AddDurationType do
  use Ecto.Migration

  def change do
    rename table(:plays), to: table(:durations)

    execute "CREATE TYPE duration_type AS ENUM ('play', 'rebuffering', 'fullscreen')"

    alter table(:durations) do
      add :type, :duration_type, default: "play"
    end
  end
end
