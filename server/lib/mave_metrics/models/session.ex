defmodule MaveMetrics.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(timestamp)a
  @optional_fields ~w(browser platform device uri_host uri_path)a

  schema "sessions" do
    field(:timestamp, :utc_datetime_usec)

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

    belongs_to(:video, MaveMetrics.Video)
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:video)
  end
end
