defmodule MaveMetrics.Session.Play do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  @required_fields ~w(timestamp from)a
  @optional_fields ~w(session_id to elapsed_time)a

  schema "plays" do
    field :timestamp, :utc_datetime_usec, primary_key: true
    belongs_to :session, MaveMetrics.Session, primary_key: true

    field :from, :float
    field :to, :float

    field :elapsed_time, :float
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:session)
  end
end
