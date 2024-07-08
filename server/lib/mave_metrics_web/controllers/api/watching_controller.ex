defmodule MaveMetricsWeb.API.WatchingController do
  use MaveMetricsWeb, :controller

  alias MaveMetrics.API

  def get_watching(conn, _params) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    params = Jason.decode!(body)
    conn |> watching(params)
  end

  def watching(conn, %{"query" => filters} = params) do
    result =
      API.get_watching(filters)

    conn
    |> json(%{watching: result})
    |> halt
  end

  def watching(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Requires a valid JSON query struct."})
    |> halt
  end
end
