defmodule MaveMetrics.Session.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  @required_fields ~w(name timestamp session_id)a
  @optional_fields ~w()a

  schema "events" do
    field :name, Ecto.Enum, values: [
      :durationchange,
      :loadedmetadata,
      :loadeddata,
      :canplay,
      :canplaythrough,
      :play,
      :playing,
      :pause,
      :seeked,
      :ratechange,
      :volumechange,
      :rebuffering_start,
      :rebuffering_end,
      :playback_failure,
      :fullscreen_enter,
      :fullscreen_exit,
      :source_set,
      :track_set
    ], primary_key: true

    field :timestamp, :utc_datetime_usec, primary_key: true
    belongs_to :session, MaveMetrics.Session, primary_key: true
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:session)
    |> unique_constraint([:name, :timestamp, :session_id])
  end
end
