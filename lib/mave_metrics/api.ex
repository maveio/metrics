defmodule MaveMetrics.API do
  @moduledoc """
  The API context.
  """

  import Ecto.Query, warn: false
  import EctoCase
  alias MaveMetrics.Repo

  use Nebulex.Caching
  alias MaveMetrics.PartitionedCache, as: Cache

  @default_timeframe "7 days"
  @default_interval "12 months"
  @default_minimum_watch_seconds 1
  @default_ranges 10

  @ttl :timer.seconds(30)

  alias MaveMetrics.Session.Duration

  @decorate cacheable(
              cache: Cache,
              key:
                {Duration,
                 "plays" <>
                   key(query) <> key(interval) <> key(timeframe) <> key(minimum_watch_seconds)},
              opts: [ttl: @ttl]
            )
  def get_plays(query, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    result =
      Duration
      |> where([d], d.type == :play)
      |> join(:left, [d], s in assoc(d, :session))
      |> join(:left, [d, s], v in assoc(s, :video))
      |> where_query(query)
      |> where_timeframe(timeframe)
      |> group_by([d, s, v], [
        fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
        d.session_id,
        s.platform,
        s.device_type,
        s.browser_type
      ])
      |> select_details(interval)
      |> subquery()
      |> where([e], e.elapsed_time >= ^minimum_watch_seconds)
      |> group_by([e], e.interval)
      |> format_output()
      |> Repo.all()

    result
  end

  @decorate cacheable(
              cache: Cache,
              key: {Duration, "engagement" <> key(query) <> key(timeframe) <> key(ranges)},
              opts: [ttl: @ttl]
            )
  def get_engagement(query, timeframe, ranges) do
    timeframe = timeframe || @default_timeframe
    ranges = ranges || @default_ranges

    last_point =
      Duration
      |> where([d], d.type == :play)
      |> join(:left, [d], s in assoc(d, :session))
      |> join(:left, [d, s], v in assoc(s, :video))
      |> where_query(query)
      |> where_timeframe(timeframe)
      |> select([d, s, v], max(d.to))
      |> Repo.one()

    if is_nil(last_point) do
      []
    else
      part = last_point / ranges

      {:ok, result} =
        Repo.transaction(fn ->
          0..(ranges - 1)
          |> Enum.map(fn m ->
            from_moment = part * m
            to_moment = part * (m + 1)

            result =
              Duration
              |> where([d], d.type == :play)
              |> join(:left, [d], s in assoc(d, :session))
              |> join(:left, [d, s], v in assoc(s, :video))
              |> where_query(query)
              |> where_timeframe(timeframe)
              |> select([d, s, v], %{from: d.from, to: d.to})
              |> subquery()
              # starts within range
              |> where([e], e.from >= ^from_moment and e.from <= ^from_moment)
              # starts before range and ends after range
              |> or_where([e], e.from < ^from_moment and e.to > ^to_moment)
              # starts before range and ends within range
              |> or_where(
                [e],
                e.from < ^from_moment and e.to >= ^from_moment and e.to <= ^to_moment
              )
              |> Repo.all()

            %{
              range: m,
              viewers: result |> Enum.count(),
              range_time: %{from: from_moment, to: to_moment}
            }
          end)
          |> Enum.sort(&(&1.range < &2.range))
        end)

      result
    end
  end

  @decorate cacheable(
              cache: Cache,
              key:
                {Duration,
                 "source" <>
                   key(query) <> key(interval) <> key(timeframe) <> key(minimum_watch_seconds)},
              opts: [ttl: @ttl]
            )
  def get_sources(query, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    result =
      Duration
      |> join(:left, [d], s in assoc(d, :session))
      |> join(:left, [d, s], v in assoc(s, :video))
      |> where_query(query)
      |> where_timeframe(timeframe)
      |> group_by([d, s, v], [
        fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
        d.session_id,
        v.source_uri
      ])
      |> select([d, s, v], %{
        host: fragment(~s|(? ->> ?)|, v.source_uri, "host"),
        path: fragment(~s|(? ->> ?)|, v.source_uri, "path"),
        interval: fragment(~s|time_bucket('?', ?)|, literal(^interval), d.timestamp),
        elapsed_time: sum(d.elapsed_time)
      })
      |> subquery()
      |> where([e], e.elapsed_time >= ^minimum_watch_seconds)
      |> having([e], sum(e.elapsed_time) >= ^minimum_watch_seconds)
      |> group_by([e], [e.host, e.path, e.interval])
      |> select([e], %{
        interval: e.interval,
        host: e.host,
        path: e.path,
        views: count(e.interval)
      })
      |> Repo.all()

    result
  end

  defp where_query(q, {identifier, query}) do
    q
    |> where_query(query)
    |> where_query(identifier)
  end

  defp where_query(q, %{"video" => video_query, "session" => session_query} = _query) do
    q |> where_query(%{"video" => video_query}) |> where_query(%{"session" => session_query})
  end

  defp where_query(q, %{"video" => video_query} = _query) do
    q |> where([d, s, v], fragment("? @> ?", v.metadata, ^video_query))
  end

  defp where_query(q, %{"session" => session_query} = _query) do
    q |> where([d, s, v], fragment("? @> ?", s.metadata, ^session_query))
  end

  defp where_query(q, query) do
    q |> where([d, s, v], v.identifier == ^query)
  end

  defp select_details(query, interval) do
    query
    |> select([d, s, v], %{
      interval: fragment("time_bucket('?', ?)", literal(^interval), d.timestamp),
      elapsed_time: sum(d.elapsed_time),
      platform_mac: case_when(s.platform == :mac, 1, 0),
      platform_ios: case_when(s.platform == :ios, 1, 0),
      platform_android: case_when(s.platform == :android, 1, 0),
      platform_windows: case_when(s.platform == :windows, 1, 0),
      platform_linux: case_when(s.platform == :linux, 1, 0),
      platform_other: case_when(s.platform == :other, 1, 0),
      device_mobile: case_when(s.device_type == :mobile, 1, 0),
      device_desktop: case_when(s.device_type == :desktop, 1, 0),
      device_tablet: case_when(s.device_type == :tablet, 1, 0),
      device_other: case_when(s.device_type == :other, 1, 0),
      browser_edge: case_when(s.browser_type == :edge, 1, 0),
      browser_ie: case_when(s.browser_type == :ie, 1, 0),
      browser_chrome: case_when(s.browser_type == :chrome, 1, 0),
      browser_firefox: case_when(s.browser_type == :firefox, 1, 0),
      browser_opera: case_when(s.browser_type == :opera, 1, 0),
      browser_safari: case_when(s.browser_type == :safari, 1, 0),
      browser_brave: case_when(s.browser_type == :brave, 1, 0),
      browser_other: case_when(s.browser_type == :other, 1, 0)
    })
  end

  defp format_output(query) do
    query
    |> select([e], %{
      interval: e.interval,
      views: count(e.interval),
      total_view_time: sum(e.elapsed_time),
      platform: %{
        mac: sum(e.platform_mac),
        ios: sum(e.platform_ios),
        android: sum(e.platform_android),
        windows: sum(e.platform_windows),
        linux: sum(e.platform_linux),
        other: sum(e.platform_other)
      },
      device_type: %{
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
  end

  defp where_timeframe(query, %{"from" => from_timestamp, "to" => to_timestamp}) do
    {:ok, from} = DateTime.from_unix(from_timestamp)
    {:ok, to} = DateTime.from_unix(to_timestamp)

    query
    |> where([d, s, v], d.timestamp >= ^from)
    |> where([d, s, v], d.timestamp <= ^to)
  end

  defp where_timeframe(query, timeframe) when is_number(timeframe) do
    {:ok, from} = DateTime.from_unix(timeframe)

    query
    |> where([d, s, v], d.timestamp >= ^from)
  end

  defp where_timeframe(query, timeframe) do
    query
    |> where([d, s, v], d.timestamp >= fragment("now() - interval '?'", literal(^timeframe)))
  end

  defp key(%{} = query) do
    Enum.map_join(query, ", ", fn {k, v} -> ~s{"#{key(k)}":"#{key(v)}"} end)
  end

  defp key(key), do: "#{key}"
end
