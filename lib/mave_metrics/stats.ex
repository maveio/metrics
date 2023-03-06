defmodule MaveMetrics.Stats do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias MaveMetrics.Repo
  alias Ecto.Changeset

  alias MaveMetrics.Video
  alias MaveMetrics.Session
  alias MaveMetrics.Session.Event
  alias MaveMetrics.Session.Play
  alias MaveMetrics.Session.Track
  alias MaveMetrics.Session.Source

  def find_or_create_video(source_url, identifier, metadata \\ %{}) do
    case get_by_source_url_and_identifier(source_url, identifier) do
      nil ->
        create_video(%{source_uri: source_url, identifier: identifier, metadata: metadata})
      video ->
        if Morphix.equaliform?(video.metadata, metadata) do
          {:ok, video}
        else
          video
          |> Video.changeset(%{metadata: metadata})
          |> Repo.update()
        end
    end
  end

  def get_by_source_url_and_identifier(source_url, identifier) do
    Video
    |> where([v], v.source_uri == ^source_url)
    |> where([v], v.identifier == ^identifier)
    |> Repo.one()
  end

  def create_video(attrs) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert()
  end

  def create_session(%Video{} = video, attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs |> Map.put(:timestamp, DateTime.utc_now()))
    |> Changeset.put_assoc(:video, video)
    |> Repo.insert()
  end

  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert!()
  end

  def get_last_play_event(session_id) do
    Event
    |> where([e], e.session_id == ^session_id)
    |> where([e], e.name == :play)
    |> order_by([e], desc: e.timestamp)
    |> limit(1)
    |> Repo.one()
  end

  def play_event_not_paused?(session_id) do
    case get_last_play_event(session_id) do
      nil ->
        false
      event ->
        Event
        |> where([e], e.session_id == ^session_id)
        |> where([e], e.name == :pause)
        |> where([e], e.timestamp > ^event.timestamp)
        |> limit(1)
        |> Repo.one()
        |> case do
          nil ->
            true
          _ ->
            false
        end
    end
  end

  def create_play(attrs) do
    %Play{}
    |> Play.changeset(attrs)
    |> Repo.insert!()
  end

  def get_last_play(session_id) do
    Play
    |> where([p], p.session_id == ^session_id)
    |> where([p], is_nil(p.to))
    |> order_by([p], desc: p.from)
    |> limit(1)
    |> Repo.one()
  end

  def update_play(%Play{} = play, attrs) do
    play
    |> Play.changeset(attrs)
    |> Repo.update()
  end

  def create_track(attrs) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert!()
  end

  def create_source(attrs) do
    %Source{}
    |> Source.changeset(attrs)
    |> Repo.insert!()
  end
end
