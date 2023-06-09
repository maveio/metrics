defmodule MaveMetrics.Repo.Migrations.CreatePublicKeys do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:keys) do
      add :key, :string, null: false
      add :disabled_at, :utc_datetime_usec

      timestamps()
    end

    create_if_not_exists unique_index(:keys, [:key])

    alter table(:sessions) do
      add :key_id, references(:keys), on_delete: :delete_all
    end

    create_if_not_exists index(:sessions, [:key_id])
  end
end
