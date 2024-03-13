defmodule MaveMetrics.Stats do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias MaveMetrics.Repo
  alias Ecto.Changeset
  alias PgRanges.Int4Range

  alias MaveMetrics.{Key, Video, Session, Event, Duration}

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
    regular =
      events
      |> Enum.reject(&(&1.type == :disconnect))
      |> Enum.map(&float_video_time/1)
      |> Enum.sort_by(& &1.timestamp)

    {_, created_events} = Repo.insert_all(Event, regular, returning: true)

    # get play events that do not end with pause event using disconnects
    disconnects =
      events
      |> Enum.filter(&(&1.type == :disconnect))
      |> Enum.map(&finish_session/1)
      |> Enum.filter(&(not is_nil(&1)))
      |> Enum.map(&float_video_time/1)

    {_, created_pauses} = Repo.insert_all(Event, disconnects, returning: true)

    created_events =
      if created_pauses do
        created_events ++ created_pauses
      else
        created_events
      end

    durations = create_durations(created_events)
    Repo.insert_all(Duration, durations)
  end

  def finish_session(%{timestamp: timestamp, session_id: session_id, video_id: video_id}) do
    # check if last event with session_id is a pause event, otherwise get the last play event
    last_event =
      Event
      |> where([e], e.session_id == ^session_id and e.video_id == ^video_id)
      |> order_by(desc: :timestamp)
      |> limit(1)
      |> Repo.one()

    if not is_nil(last_event) and last_event.type == :play do
      # no pause event, create a pause event
      elapsed_time = DateTime.diff(timestamp, last_event.timestamp, :microsecond) / 1_000_000
      to = last_event.video_time + elapsed_time

      %{
        type: :pause,
        video_time: to,
        timestamp: timestamp,
        session_id: session_id,
        video_id: video_id
      }
    else
      # last event is a pause event, do nothing
      nil
    end
  end

  def create_durations(events) do
    events
    |> Enum.filter(&(&1.type == :pause))
    |> Enum.map(fn pause_event ->
      play_event = find_play_event_for(pause_event, events)

      watched_seconds =
        Int4Range.new(
          round(play_event.video_time),
          (Float.floor(pause_event.video_time) |> trunc()) + 1
        )

      overlapping_durations =
        Duration
        |> where(
          [d],
          d.session_id == ^pause_event.session_id and d.video_id == ^pause_event.video_id
        )
        |> where([d], fragment("? && ?", d.watched_seconds, type(^watched_seconds, Int4Range)))
        |> select([d], %{
          overlap:
            fragment(
              "upper(? * ?) - lower(? * ?)",
              d.watched_seconds,
              type(^watched_seconds, Int4Range),
              d.watched_seconds,
              type(^watched_seconds, Int4Range)
            )
        })
        |> Repo.all()

      total_duration = round(pause_event.video_time) - round(play_event.video_time) + 1
      total_overlap = Enum.sum(for %{overlap: o} <- overlapping_durations, do: o)
      uniqueness = (total_duration - total_overlap) / total_duration
      uniqueness = if uniqueness < 0, do: 0, else: uniqueness

      session = Session |> Repo.get!(pause_event.session_id)

      %{
        timestamp: pause_event.timestamp,
        duration: Float.round(pause_event.video_time - play_event.video_time, 2),
        session_id: pause_event.session_id,
        video_id: pause_event.video_id,
        uniqueness: uniqueness,
        watched_seconds: watched_seconds,
        browser: session.browser,
        platform: session.platform,
        device: session.device,
        uri_host: session.uri_host,
        uri_path: session.uri_path
      }
    end)
  end

  defp find_play_event_for(pause_event, events) do
    event =
      events
      |> Enum.filter(
        &(&1.session_id == pause_event.session_id and &1.video_id == pause_event.video_id and
            &1.type == :play and &1.timestamp < pause_event.timestamp)
      )
      |> Enum.sort_by(& &1.timestamp)
      |> Enum.reverse()
      |> Enum.at(0)

    if is_nil(event) do
      Event
      |> where(
        [e],
        e.session_id == ^pause_event.session_id and e.type == :play and
          e.timestamp < ^pause_event.timestamp
      )
      |> order_by(desc: :timestamp)
      |> limit(1)
      |> Repo.one()
    else
      event
    end
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
