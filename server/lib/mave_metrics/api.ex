defmodule MaveMetrics.API do
  @moduledoc """
  The API context.
  """

  import Ecto.Query, warn: false
  import EctoCase
  alias MaveMetrics.{Repo, Video, Duration, Key}
  alias MaveMetricsWeb.Presence

  use Nebulex.Caching
  alias MaveMetrics.PartitionedCache, as: Cache

  @ttl :timer.hours(90 * 24)

  @default_timeframe "7 days"
  @default_interval "12 months"
  @default_minimum_watch_seconds 1

  def get_watching(%{"video" => query}) do
    videos_for_metadata(query)
    |> get_watching_by_videos()
  end

  def get_watching(%{"key" => key}) do
    videos_for_key(key)
    |> get_watching_by_videos()
  end

  def get_watching(_), do: 0

  defp get_watching_by_videos(video_ids) do
    if video_ids == [] do
      0
    else
      video_ids |> Enum.map(&map_size(Presence.list("video:#{&1}"))) |> Enum.sum()
    end
  end

  def get_plays(%{"video" => query}, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    videos_for_metadata(query)
    |> get_plays_by_videos(interval, timeframe, minimum_watch_seconds)
  end

  def get_plays(%{"key" => key}, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    videos_for_key(key)
    |> get_plays_by_videos(interval, timeframe, minimum_watch_seconds)
  end

  def get_plays(_), do: []

  defp get_plays_by_videos(video_ids, interval, timeframe, minimum_watch_seconds) do
    if video_ids == [] do
      []
    else
      query_aggregated_video_metrics(video_ids, timeframe, minimum_watch_seconds, interval)
    end
  end

  def get_sources(%{"video" => query}, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    videos_for_metadata(query)
    |> get_sources_by_videos(interval, timeframe, minimum_watch_seconds)
  end

  def get_sources(%{"key" => key}, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    videos_for_key(key)
    |> get_sources_by_videos(interval, timeframe, minimum_watch_seconds)
  end

  def get_sources(_), do: []

  defp get_sources_by_videos(video_ids, interval, timeframe, minimum_watch_seconds) do
    if video_ids == nil or video_ids == [] do
      []
    else
      query_individual_video_by_url(video_ids, timeframe, minimum_watch_seconds, interval)
    end
  end

  def get_engagement(%{"video" => query}, interval, timeframe) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe

    video_ids =
      Video
      |> where([v], fragment("? @> ?", v.metadata, ^query))
      |> select([v], v.id)
      |> Repo.all()

    if video_ids == nil or video_ids == [] do
      []
    else
      query_individual_video_engagement(video_ids, timeframe, interval)
    end
  end

  def query_aggregated_video_metrics(video_ids, timeframe, min_watched_seconds, interval) do
    if timeframe_excludes_today?(timeframe) do
      cached_query_aggregated_video_metrics(video_ids, timeframe, min_watched_seconds, interval)
    else
      uncached_query_aggregated_video_metrics(video_ids, timeframe, min_watched_seconds, interval)
    end
  end

  defp videos_for_metadata(query) do
    Video
    |> where([v], fragment("? @> ?", v.metadata, ^query))
    |> select([v], v.id)
    |> Repo.all()
  end

  defp videos_for_key(key) do
    Video
    |> join(:left, [v], k in Key, on: k.key == ^key)
    |> where([v, k], v.key_id == k.id)
    |> select([v], v.id)
    |> Repo.all()
  end

  @decorate cacheable(
              cache: Cache,
              key: {video_ids, timeframe, min_watched_seconds, interval},
              opts: [ttl: @ttl]
            )
  defp cached_query_aggregated_video_metrics(video_ids, timeframe, min_watched_seconds, interval) do
    execute_query(video_ids, timeframe, min_watched_seconds, interval)
  end

  defp uncached_query_aggregated_video_metrics(
         video_ids,
         timeframe,
         min_watched_seconds,
         interval
       ) do
    execute_query(video_ids, timeframe, min_watched_seconds, interval)
  end

  defp execute_query(video_ids, timeframe, min_watched_seconds, interval) do
    Duration
    |> apply_timeframe(timeframe)
    |> where([d], d.video_id in ^video_ids)
    |> where([d], d.duration >= ^min_watched_seconds)
    |> group_by([d], [
      fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
      d.timestamp,
      d.session_id,
      d.platform,
      d.device,
      d.browser
    ])
    |> select([d], %{
      session_id: d.session_id,
      interval: fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
      total_view_time: sum(d.duration),
      unique_total_view_time: sum(fragment("? * ?", d.duration, d.uniqueness)),
      platform_mac: case_when(d.platform == :mac, 1, 0),
      platform_ios: case_when(d.platform == :ios, 1, 0),
      platform_android: case_when(d.platform == :android, 1, 0),
      platform_windows: case_when(d.platform == :windows, 1, 0),
      platform_linux: case_when(d.platform == :linux, 1, 0),
      platform_other: case_when(d.platform == :other, 1, 0),
      device_mobile: case_when(d.device == :mobile, 1, 0),
      device_desktop: case_when(d.device == :desktop, 1, 0),
      device_tablet: case_when(d.device == :tablet, 1, 0),
      device_other: case_when(d.device == :other, 1, 0),
      browser_edge: case_when(d.browser == :edge, 1, 0),
      browser_ie: case_when(d.browser == :ie, 1, 0),
      browser_chrome: case_when(d.browser == :chrome, 1, 0),
      browser_firefox: case_when(d.browser == :firefox, 1, 0),
      browser_opera: case_when(d.browser == :opera, 1, 0),
      browser_safari: case_when(d.browser == :safari, 1, 0),
      browser_brave: case_when(d.browser == :brave, 1, 0),
      browser_other: case_when(d.browser == :other, 1, 0)
    })
    |> subquery()
    |> group_by([d], [d.interval])
    |> select([e], %{
      interval: e.interval,
      views: count(e.session_id),
      total_view_time: sum(e.total_view_time),
      unique_total_view_time: sum(e.unique_total_view_time),
      platform: %{
        mac: sum(e.platform_mac),
        ios: sum(e.platform_ios),
        android: sum(e.platform_android),
        windows: sum(e.platform_windows),
        linux: sum(e.platform_linux),
        other: sum(e.platform_other)
      },
      device: %{
        mobile: sum(e.device_mobile),
        desktop: sum(e.device_desktop),
        tablet: sum(e.device_tablet),
        other: sum(e.device_other)
      },
      browser: %{
        edge: sum(e.browser_edge),
        ie: sum(e.browser_ie),
        chrome: sum(e.browser_chrome),
        firefox: sum(e.browser_firefox),
        opera: sum(e.browser_opera),
        safari: sum(e.browser_safari),
        brave: sum(e.browser_brave),
        other: sum(e.browser_other)
      }
    })
    |> Repo.all()
  end

  def query_individual_video_by_url(video_ids, timeframe, min_watched_seconds, interval) do
    Duration
    |> apply_timeframe(timeframe)
    |> where([d], d.video_id in ^video_ids)
    |> where([d], d.duration >= ^min_watched_seconds)
    |> group_by([d], [
      fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
      d.uri_host,
      d.uri_path
    ])
    |> select([d], %{
      interval: fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
      host: d.uri_host,
      path: d.uri_path,
      views: count(d.session_id)
    })
    |> Repo.all()
  end

  def query_individual_video_engagement(video_ids, timeframe, interval) do
    bucket_query =
      Duration
      |> where([d], d.video_id in ^video_ids)
      |> apply_timeframe(timeframe)
      |> join(
        :inner_lateral,
        [d],
        gs in fragment(
          "SELECT generate_series(lower(?), upper(?) - 1) AS second",
          d.watched_seconds,
          d.watched_seconds
        ),
        on: true
      )
      |> group_by([d, gs], [
        fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
        gs.second
      ])
      |> order_by([d, gs],
        asc: fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
        asc: gs.second
      )
      |> select([d, gs], %{
        interval: fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
        second: gs.second,
        views: count()
      })
      |> subquery()

    query =
      from(e in bucket_query,
        group_by: e.interval,
        order_by: e.interval,
        select: %{
          interval: e.interval,
          per_second:
            fragment(
              "json_agg(json_build_object('second', ?, 'views', ?) ORDER BY ?)",
              e.second,
              e.views,
              e.second
            )
        }
      )

    Repo.all(query)
  end

  defp apply_timeframe(query, timeframe, date_field \\ :timestamp)

  defp apply_timeframe(
         query,
         %{"from" => from_timestamp, "to" => to_timestamp},
         date_field
       ) do
    from =
      DateTime.from_unix!(from_timestamp, :second)
      |> DateTime.truncate(:microsecond)

    to =
      DateTime.from_unix!(to_timestamp, :second)
      |> DateTime.truncate(:microsecond)

    query
    |> where([d], field(d, ^date_field) >= ^from and field(d, ^date_field) <= ^to)
  end

  defp apply_timeframe(query, timeframe, date_field) when is_number(timeframe) do
    from =
      DateTime.from_unix!(timeframe, :second)
      |> DateTime.truncate(:microsecond)

    query
    |> where([d], field(d, ^date_field) >= ^from)
  end

  defp apply_timeframe(query, timeframe, date_field) when is_binary(timeframe) do
    query
    |> where(
      [d],
      field(d, ^date_field) >= fragment(~s|now() - interval '?'|, literal(^timeframe))
    )
  end

  defp should_cache?({video_ids, timeframe, min_watched_seconds, interval}) do
    timeframe_excludes_today?(timeframe)
  end

  defp timeframe_excludes_today?(%{"from" => from_timestamp, "to" => to_timestamp}) do
    today = Date.utc_today()

    from_date =
      DateTime.from_unix!(from_timestamp, :second)
      |> DateTime.to_date()

    to_date =
      DateTime.from_unix!(to_timestamp, :second)
      |> DateTime.to_date()

    # Return true if today is NOT between the "from" and "to" dates (i.e. timeframe excludes today)
    not (from_date <= today and to_date >= today)
  end

  defp timeframe_excludes_today?(_other), do: true
end
