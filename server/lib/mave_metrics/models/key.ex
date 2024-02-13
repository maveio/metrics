defmodule MaveMetrics.Key do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(key)a
  @optional_fields ~w(disabled_at)a

  schema "keys" do
    field(:key, :string)
    field(:disabled_at, :utc_datetime_usec)
    timestamps()
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
