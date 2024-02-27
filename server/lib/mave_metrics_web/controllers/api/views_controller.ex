defmodule MaveMetricsWeb.API.ViewsController do
  use MaveMetricsWeb, :controller

  alias MaveMetrics.API

  def get_views(conn, _params) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    params = Jason.decode!(body)
    conn |> views(params)
  end

  def views(conn, %{"query" => filters} = params) do
    result =
      API.get_plays(
        filters,
        params["interval"],
        params["timeframe"],
        params["minimum_watch_seconds"]
      )

    conn
    |> json(%{views: result})
    |> halt
  end

  def views(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Requires a valid JSON query struct."})
    |> halt
  end
end
