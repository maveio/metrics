defmodule MaveMetrics.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  @required_fields ~w(type timestamp video_time session_id)a
  @optional_fields ~w()a

  schema "events" do
    field(:timestamp, :utc_datetime_usec)

    field(:video_time, :float)

    field(:type, Ecto.Enum,
      values: [
        :play,
        :pause
      ]
    )

    belongs_to(:session, MaveMetrics.Session)
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
