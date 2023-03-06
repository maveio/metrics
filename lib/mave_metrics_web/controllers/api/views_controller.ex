defmodule MaveMetricsWeb.API.ViewsController do
  use MaveMetricsWeb, :controller

  alias MaveMetrics.API

  def views(conn, %{"identifier" => identifier, "query" => query} = params) do
    result = API.get_plays({identifier, query}, params["interval"], params["timeframe"], params["minimum_watch_seconds"])

    conn
    |> json(result)
    |> halt
  end

  def views(conn, %{"identifier" => identifier} = params) do
    result = API.get_plays(identifier, params["interval"], params["timeframe"], params["minimum_watch_seconds"])

    conn
    |> json(result)
    |> halt
  end

  def views(conn, %{"query" => filters} = params) do
    result = API.get_plays(filters, params["interval"], params["timeframe"], params["minimum_watch_seconds"])

    conn
    |> json(result)
    |> halt
  end

  def views(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Requires a valid JSON query struct."})
    |> halt
  end
end
