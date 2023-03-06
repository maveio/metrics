defmodule MaveMetrics.Session.Track do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  @required_fields ~w(timestamp language)a
  @optional_fields ~w(session_id)a

  schema "tracks" do
    field :timestamp, :utc_datetime_usec, primary_key: true
    belongs_to :session, MaveMetrics.Session, primary_key: true

    field :language, Ecto.Enum, values: [:af,:am,:ar,:as,:az,:ba,:be,:bg,:bn,:bo,:br,:bs,:ca,:cs,:cy,:da,:de,:el,:en,:es,:et,:eu,:fa,:fi,:fo,:fr,:gl,:gu,:ha,:haw,:hi,:hr,:ht,:hu,:hy,:id,:is,:it,:iw,:ja,:jw,:ka,:kk,:km,:kn,:ko,:la,:lb,:ln,:lo,:lt,:lv,:mg,:mi,:mk,:ml,:mn,:mr,:ms,:mt,:my,:ne,:nl,:nn,:no,:oc,:pa,:pl,:ps,:pt,:ro,:ru,:sa,:sd,:si,:sk,:sl,:sn,:so,:sq,:sr,:su,:sv,:sw,:ta,:te,:tg,:th,:tk,:tl,:tr,:tt,:uk,:ur,:uz,:vi,:yi,:yo,:zh]
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:session)
  end
end
