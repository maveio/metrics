defmodule MaveMetrics.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @required_fields ~w()a
  @optional_fields ~w(browser_type platform device_type metadata)a

  schema "sessions" do
    field :browser_type, Ecto.Enum, values: [:edge, :ie, :chrome, :firefox, :opera, :safari, :brave, :other], default: :other
    field :platform, Ecto.Enum, values: [:ios, :android, :mac, :windows, :linux, :other], default: :other
    field :device_type, Ecto.Enum, values: [:mobile, :tablet, :desktop, :other], default: :other

    belongs_to :video, MaveMetrics.Video

    has_many :events, MaveMetrics.Session.Event
    has_many :sources, MaveMetrics.Session.Source
    has_many :plays, MaveMetrics.Session.Play

    field :metadata, :map

    timestamps()
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:video)
  end
end
