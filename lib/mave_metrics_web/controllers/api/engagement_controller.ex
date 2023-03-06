defmodule MaveMetricsWeb.API.EngagementController do
  use MaveMetricsWeb, :controller

  alias MaveMetrics.API

  def engagement(conn, %{"identifier" => identifier, "query" => query} = params) do
    result = API.get_engagement({identifier, query}, params["timeframe"], params["ranges"])

    conn
    |> json(result)
    |> halt
  end

  def engagement(conn, %{"identifier" => identifier} = params) do
    result = API.get_engagement(identifier, params["timeframe"], params["ranges"])

    conn
    |> json(result)
    |> halt
  end

  def engagement(conn, %{"query" => filters} = params) do
    result = API.get_engagement(filters, params["timeframe"], params["ranges"])

    conn
    |> json(result)
    |> halt
  end

  def engagement(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Requires a valid JSON query struct."})
    |> halt
  end
end
