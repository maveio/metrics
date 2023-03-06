defmodule MaveMetrics.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @requires_https_message "We need https to make it work"
  @invalid_message "This doesn't seem like a valid url"

  @required_fields ~w(identifier source_uri)a
  @optional_fields ~w(metadata)a

  schema "videos" do
    field :identifier, :string
    field :source_uri, EctoURI

    field :metadata, :map

    timestamps()
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_length(:identifier, min: 1, max: 255)
    # |> cast_embed(:metadata)
  end
end
