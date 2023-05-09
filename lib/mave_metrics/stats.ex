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

  # returns existing videos that aren't part of that video
  def find_or_create_video(source_url, identifier, metadata) do
    case get_by_source_url_and_identifier_and_metadata(source_url, identifier, metadata) do
      %Video{id: _id} = video ->
        {:ok, video}
        # if Morphix.equaliform?(video.metadata, metadata) do
        #   {:ok, video}
        # else
        #   video
        #   |> Video.changeset(%{metadata: metadata})
        #   |> Repo.update()
        # end
      _ ->
        create_video(%{source_uri: source_url, identifier: identifier, metadata: metadata})
    end
  end

  def get_by_source_url_and_identifier_and_metadata(source_url, identifier, metadata) do
    Video
    |> where([v], v.identifier == ^identifier)
    |> where([v], v.source_uri == ^source_url)
    |> optional_metadata(metadata)
    |> Repo.one()
  end

  def optional_metadata(query, %{} = metadata) do
    query
    |> where([v], v.metadata == ^metadata)
  end

  def optional_metadata(query, _metadata), do: query

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
