defmodule MaveMetrics.API do
  @moduledoc """
  The API context.
  """

  import Ecto.Query, warn: false
  import EctoCase
  alias MaveMetrics.Repo

  @default_timeframe "7 days"
  @default_interval "12 months"
  @default_minimum_watch_seconds 1
  @default_ranges 10

  alias MaveMetrics.Session.Play

  # import Timescale.Hyperfunctions
  # https://medium.com/hackernoon/how-to-query-jsonb-beginner-sheet-cheat-4da3aa5082a3

  def get_plays(query, interval, timeframe, minimum_watch_seconds) do
    interval = interval || @default_interval
    timeframe = timeframe || @default_timeframe
    minimum_watch_seconds = minimum_watch_seconds || @default_minimum_watch_seconds

    result = Play
    |> join(:left, [p], s in assoc(p, :session))
    |> join(:left, [p, s], v in assoc(s, :video))
    |> where_query(query)
    |> where_timeframe(timeframe)
    |> group_by([p, s, v], [fragment("time_bucket('?', ?)", literal(^interval), p.timestamp), p.session_id, s.platform, s.device_type, s.browser_type])
    |> select_details(interval)
    |> subquery()
    |> where([e], e.elapsed_time >= ^minimum_watch_seconds)
    |> having([e], sum(e.elapsed_time) >= ^minimum_watch_seconds)
    |> group_by([e], e.interval)
    |> format_output()
    |> Repo.all()

    result
  end


  def get_engagement(query, timeframe, ranges) do
    timeframe = timeframe || @default_timeframe
    ranges = ranges || @default_ranges

    last_point =
      Play
      |> join(:left, [p], s in assoc(p, :session))
      |> join(:left, [p, s], v in assoc(s, :video))
      |> where_query(query)
      |> where_timeframe(timeframe)
      |> select([p, s, v], max(p.to))
      |> Repo.one()

    if is_nil(last_point) do
      []
    else
      part = last_point / ranges

      {:ok, result} = Repo.transaction(fn ->
        0 .. ranges - 1 |> Enum.map(fn m ->
          from_moment = part * m
          to_moment = part * (m + 1)

          result = Play
          |> join(:left, [p], s in assoc(p, :session))
          |> join(:left, [p, s], v in assoc(s, :video))
          |> where_query(query)
          |> where_timeframe(timeframe)
          |> select([p, s, v], %{from: p.from, to: p.to})
          |> subquery()
          |> where([e], e.from >= ^from_moment and e.from <= ^from_moment) # starts within range
          |> or_where([e], e.from < ^from_moment and e.to > ^to_moment) # starts before range and ends after range
          |> or_where([e], e.from < ^from_moment and e.to >= ^from_moment and e.to <= ^to_moment) # starts before range and ends within range
          |> Repo.all()

          %{range: m, viewers: result |> Enum.count, range_time: %{from: from_moment, to: to_moment}}
        end) |> Enum.sort(&(&1.range < &2.range))
      end)

      result
    end
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
    q |> where([p, s, v], fragment("? @> ?", v.metadata, ^video_query))
  end

  defp where_query(q, %{"session" => session_query} = _query) do
    q |> where([p, s, v], fragment("? @> ?", s.metadata, ^session_query))
  end

  defp where_query(q, query) do
    q |> where([p, s, v], v.identifier == ^query)
  end

  defp select_details(query, interval) do
    query
    |> select([p, s, v], %{
      interval: fragment("time_bucket('?', ?)", literal(^interval), p.timestamp),
      elapsed_time: sum(p.elapsed_time),
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

    dbg from
    dbg to

    query
    |> where([p, s, v], p.timestamp >= ^from)
    |> where([p, s, v], p.timestamp <= ^to)
  end

  defp where_timeframe(query, timeframe) when is_number(timeframe) do
    {:ok, from} = DateTime.from_unix(timeframe)

    query
    |> where([p, s, v], p.timestamp >= ^from)
  end

  defp where_timeframe(query, timeframe) do
    query
    |> where([p, s, v], p.timestamp >= fragment("now() - interval '?'", literal(^timeframe)))
  end
end
