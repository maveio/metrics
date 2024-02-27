defmodule MaveMetricsWeb.API.EngagementController do
  use MaveMetricsWeb, :controller

  alias MaveMetrics.API

  def get_engagement(conn, _params) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    params = Jason.decode!(body)
    conn |> engagement(params)
  end

  def engagement(conn, %{"query" => query} = params) do
    result = API.get_engagement(query, params["interval"], params["timeframe"])

    conn
    |> json(%{engagement: result})
    |> halt
  end

  def engagement(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Requires a valid JSON query struct."})
    |> halt
  end
end
