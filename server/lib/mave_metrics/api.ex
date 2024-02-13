defmodule MaveMetrics.API do
  @moduledoc """
  The API context.
  """

  import Ecto.Query, warn: false
  import EctoCase
  alias MaveMetrics.Repo
  alias MaveMetrics.Video

  @default_timeframe "7 days"
  @default_interval "12 months"
  @default_minimum_watch_seconds 1

  def get_plays(%{"video" => query}, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    video_ids =
      Video
      |> where([v], fragment("? @> ?", v.metadata, ^query))
      |> select([v], v.id)
      |> Repo.all()

    query_aggregated_video_metrics(video_ids, timeframe, minimum_watch_seconds, interval)
  end

  def get_sources(%{"video" => query}, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    video_id =
      Video
      |> where([v], fragment("? @> ?", v.metadata, ^query))
      |> select([v], v.id)
      |> Repo.one()

    query_individual_video_by_url(video_id, timeframe, minimum_watch_seconds, interval)
  end

  def query_aggregated_video_metrics(video_ids, timeframe, min_watched_seconds, interval) do
    "daily_session_aggregation"
    |> apply_timeframe(timeframe)
    |> where([d], d.video_id in ^video_ids)
    |> where([d], d.session_watched_seconds >= ^min_watched_seconds)
    |> group_by([d], [
      fragment(~s|time_bucket('?', ?)|, literal(^interval), d.session_date),
      d.platform,
      d.device,
      d.browser
    ])
    |> select([d], %{
      interval: fragment(~s|time_bucket('?', ?)|, literal(^interval), d.session_date),
      total_view_time: sum(d.session_watched_seconds),
      platform_mac: case_when(d.platform == "mac", 1, 0),
      platform_ios: case_when(d.platform == "ios", 1, 0),
      platform_android: case_when(d.platform == "android", 1, 0),
      platform_windows: case_when(d.platform == "windows", 1, 0),
      platform_linux: case_when(d.platform == "linux", 1, 0),
      platform_other: case_when(d.platform == "other", 1, 0),
      device_mobile: case_when(d.device == "mobile", 1, 0),
      device_desktop: case_when(d.device == "desktop", 1, 0),
      device_tablet: case_when(d.device == "tablet", 1, 0),
      device_other: case_when(d.device == "other", 1, 0),
      browser_edge: case_when(d.browser == "edge", 1, 0),
      browser_ie: case_when(d.browser == "ie", 1, 0),
      browser_chrome: case_when(d.browser == "chrome", 1, 0),
      browser_firefox: case_when(d.browser == "firefox", 1, 0),
      browser_opera: case_when(d.browser == "opera", 1, 0),
      browser_safari: case_when(d.browser == "safari", 1, 0),
      browser_brave: case_when(d.browser == "brave", 1, 0),
      browser_other: case_when(d.browser == "other", 1, 0)
    })
    |> subquery()
    |> group_by([d], [d.interval])
    |> select([e], %{
      interval: e.interval,
      views: count(e.interval),
      total_view_time: sum(e.total_view_time),
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

  def query_individual_video_by_url(video_id, timeframe, min_watched_seconds, interval) do
    "daily_session_aggregation"
    |> apply_timeframe(timeframe)
    |> where([d], d.video_id == ^video_id)
    |> where([d], d.session_watched_seconds >= ^min_watched_seconds)
    |> group_by([d], [
      fragment(~s|time_bucket('?', ?)|, literal(^interval), d.session_date),
      d.uri_host,
      d.uri_path
    ])
    |> select([d], %{
      interval: fragment(~s|time_bucket('?', ?)|, literal(^interval), d.session_date),
      host: d.uri_host,
      path: d.uri_path,
      views: count(d.session_id)
    })
    |> Repo.all()
  end

  defp apply_timeframe(query, %{"from" => from_timestamp, "to" => to_timestamp}) do
    {:ok, from} = DateTime.from_unix(from_timestamp)
    {:ok, to} = DateTime.from_unix(to_timestamp)

    query
    |> where([d], d.session_date >= ^from and d.session_date <= ^to)
  end

  defp apply_timeframe(query, timeframe) when is_number(timeframe) do
    {:ok, from} = DateTime.from_unix(timeframe)

    query
    |> where([d], d.session_date >= ^from)
  end

  defp apply_timeframe(query, timeframe) when is_binary(timeframe) do
    query
    |> where([d], d.session_date >= fragment(~s|now() - interval '?'|, literal(^timeframe)))
  end
end
