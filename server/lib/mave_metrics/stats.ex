defmodule MaveMetrics.Stats do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias MaveMetrics.Repo
  alias Ecto.Changeset

  alias MaveMetrics.Key
  alias MaveMetrics.Video
  alias MaveMetrics.Session
  alias MaveMetrics.Event

  use Nebulex.Caching
  alias MaveMetrics.PartitionedCache, as: Cache

  @ttl :timer.seconds(30)

  @decorate cacheable(
              cache: Cache,
              key:
                {Video,
                 "id" <>
                   key(key.id) <> key(metadata)},
              opts: [ttl: @ttl]
            )
  def find_or_create_video(%Key{} = key, metadata) do
    Video
    |> where([v], v.key_id == ^key.id)
    |> where([v], v.metadata == ^metadata)
    |> Repo.one()
    |> case do
      nil ->
        key |> create_video(%{metadata: metadata})

      video ->
        {:ok, video}
    end
  end

  def create_video(%Key{} = key, attrs) do
    %Video{}
    |> Video.changeset(attrs)
    |> Changeset.put_assoc(:key, key)
    |> Repo.insert()
  end

  def create_session(%Video{} = video, attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs |> Map.put(:timestamp, DateTime.utc_now()))
    |> Changeset.put_assoc(:video, video)
    |> Repo.insert(returning: true)
  end

  def create_event(%Video{} = video, %Session{} = session, attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Changeset.put_assoc(:video, video)
    |> Changeset.put_assoc(:session, session)
    |> Repo.insert!()
  end

  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert!()
  end

  def create_events(events) when is_list(events) do
    events =
      events
      |> Enum.reject(&(&1.type == :disconnect))
      |> Enum.map(&float_video_time/1)
      |> Enum.sort_by(& &1.timestamp)

    Repo.insert_all(Event, events)

    # get play events that do not end with pause event using disconnects
    disconnects =
      events
      |> Enum.filter(&(&1.type == :disconnect))
      |> Enum.map(&finish_session/1)
      |> Enum.filter(&(not is_nil(&1)))
      |> Enum.map(&float_video_time/1)

    Repo.insert_all(Event, disconnects)
  end

  def finish_session(%{timestamp: timestamp, session_id: session_id, video_id: video_id}) do
    # check if last event with session_id is a pause event, otherwise get the last play event
    last_event =
      Event
      |> where([e], e.session_id == ^session_id)
      |> order_by(desc: :timestamp)
      |> limit(1)
      |> Repo.one()

    case last_event do
      %Event{type: :play} ->
        # no pause event, create a pause event
        elapsed_time = DateTime.diff(timestamp, last_event.timestamp, :microsecond) / 1_000_000
        to = last_event.from + elapsed_time

        %{type: :pause, to: to, timestamp: timestamp, session_id: session_id, video_id: video_id}

      _ ->
        # last event is a pause event, do nothing
        nil
    end
  end

  def refresh_daily_aggregation() do
    Repo.query!("REFRESH MATERIALIZED VIEW daily_session_aggregation;")
    Repo.query!("REFRESH MATERIALIZED VIEW video_views_per_second_per_day_aggregate;")
  end

  defp float_video_time(attrs) do
    Map.update!(attrs, :video_time, fn video_time ->
      case video_time do
        value when is_integer(value) ->
          value + 0.0

        value when is_float(value) ->
          Float.round(value, 2)

        _ ->
          0.0
      end
    end)
  end

  defp key(%{} = query) do
    Enum.map_join(query, ", ", fn {k, v} -> ~s{"#{key(k)}":"#{key(v)}"} end)
  end

  defp key(key), do: "#{key}"
end
