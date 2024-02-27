defmodule MaveMetricsWeb.API.SourcesController do
  use MaveMetricsWeb, :controller

  alias MaveMetrics.API

  def get_sources(conn, _params) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    params = Jason.decode!(body)
    conn |> sources(params)
  end

  def sources(conn, %{"query" => filters} = params) do
    result =
      API.get_sources(
        filters,
        params["interval"],
        params["timeframe"],
        params["minimum_watch_seconds"]
      )

    conn
    |> json(%{sources: result})
    |> halt
  end

  def sources(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Requires a valid JSON query struct."})
    |> halt
  end
end
