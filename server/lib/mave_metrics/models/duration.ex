defmodule MaveMetrics.Duration do
  use Ecto.Schema
  import Ecto.Changeset
  alias PgRanges.Int4Range

  @primary_key false

  @required_fields ~w(timestamp duration uniqueness watched_seconds session_id video_id browser platform device uri_host uri_path)a
  @optional_fields ~w()a

  schema "durations" do
    field(:timestamp, :utc_datetime_usec)

    field(:duration, :float)
    field(:uniqueness, :float)
    field(:watched_seconds, Int4Range)

    field(:browser, Ecto.Enum,
      values: [:edge, :ie, :chrome, :firefox, :opera, :safari, :brave, :other],
      default: :other
    )

    field(:platform, Ecto.Enum,
      values: [:ios, :android, :mac, :windows, :linux, :other],
      default: :other
    )

    field(:device, Ecto.Enum, values: [:mobile, :tablet, :desktop, :other], default: :other)

    field(:uri_host, :string)
    field(:uri_path, :string)

    belongs_to(:session, MaveMetrics.Session)
    belongs_to(:video, MaveMetrics.Video)
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
