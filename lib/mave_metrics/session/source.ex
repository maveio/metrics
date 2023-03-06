defmodule MaveMetrics.Session.Source do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  @required_fields ~w(timestamp)a
  @optional_fields ~w(session_id source_url bitrate codec width height)a

  schema "sources" do
    field :timestamp, :utc_datetime_usec, primary_key: true
    belongs_to :session, MaveMetrics.Session, primary_key: true

    field :source_url, EctoURI

    field :bitrate, :integer
    field :codec, :string
    field :width, :integer
    field :height, :integer
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:session)
  end
end
