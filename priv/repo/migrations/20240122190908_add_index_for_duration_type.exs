defmodule MaveMetrics.Repo.Migrations.AddIndexForDurationType do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:durations, [:type])
  end
end
