defmodule MaveMetrics.Stats do
  @moduledoc """
  The Stats context.
  """

  @min_rebuffering_duration 1

  import Ecto.Query, warn: false
  alias MaveMetrics.Repo
  alias Ecto.Changeset

  alias MaveMetrics.Video
  alias MaveMetrics.Session
  alias MaveMetrics.Session.Event
  alias MaveMetrics.Session.Duration
  alias MaveMetrics.Session.Track
  alias MaveMetrics.Session.Source
  alias MaveMetrics.Key

  # returns existing videos that aren't part of that video
  def find_or_create_video(source_url, identifier, metadata) do
    source_url = source_url |> URI.parse() |> Map.take([:host, :path])

    case get_by_source_url_and_identifier_and_metadata(source_url, identifier, metadata) do
      %Video{id: _id} = video ->
        {:ok, video}

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

  def create_session(%Video{} = video, %Key{} = key, attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs |> Map.put(:timestamp, DateTime.utc_now()))
    |> Changeset.put_assoc(:key, key)
    |> Changeset.put_assoc(:video, video)
    |> Repo.insert()
  end

  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert!()
  end

  def get_last_event(type, session_id) do
    Event
    |> where([e], e.session_id == ^session_id)
    |> where([e], e.name == ^type)
    |> order_by([e], desc: e.timestamp)
    |> limit(1)
    |> Repo.one()
  end

  def duration_not_closed?(type, session_id) do
    counter_type =
      case type do
        :play ->
          :pause

        :rebuffering_start ->
          :rebuffering_end

        :fullscreen_enter ->
          :fullscreen_exit
      end

    case get_last_event(type, session_id) do
      nil ->
        false

      event ->
        Event
        |> where([e], e.session_id == ^session_id)
        |> where([e], e.name == ^counter_type)
        |> where([e], e.timestamp > ^event.timestamp)
        |> limit(1)
        |> Repo.one()
        |> case do
          nil ->
            true

          _result ->
            false
        end
    end
  end

  def create_duration(attrs) do
    %Duration{}
    |> Duration.changeset(attrs)
    |> Repo.insert!()
  end

  def get_last_duration(session_id, type \\ :play) do
    Duration
    |> where([d], d.session_id == ^session_id and d.type == ^type)
    |> order_by([d], desc: d.timestamp)
    |> limit(1)
    |> Repo.one()
  end

  def update_duration(%Duration{} = duration, attrs) do
    duration
    |> Duration.changeset(attrs)
    |> Repo.update()
  end

  def update_rebuffering(duration, elapsed_time) do
    if elapsed_time > @min_rebuffering_duration do
      update_duration(duration, %{
        elapsed_time: elapsed_time
      })
    else
      delete_duration(duration)
    end
  end

  def delete_duration(%Duration{} = duration) do
    Repo.delete(duration)
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
