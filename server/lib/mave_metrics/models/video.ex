defmodule MaveMetrics.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(metadata)a
  @optional_fields ~w(key_id)a

  schema "videos" do
    field(:metadata, :map)

    belongs_to(:key, MaveMetrics.Key)

    timestamps()
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:key)
  end
end
