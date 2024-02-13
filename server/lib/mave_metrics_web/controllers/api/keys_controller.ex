defmodule MaveMetricsWeb.API.KeysController do
  use MaveMetricsWeb, :controller

  alias MaveMetrics.Keys

  def get_keys(conn, _params) do
    conn
    |> json(%{keys: Keys.get_keys()})
  end

  def create_key(conn, params) do
    case Keys.create_key(params) do
      {:ok, result} ->
        conn
        |> put_status(201)
        |> json(%{key: result})
        |> halt
      {:error, _reason} ->
        conn
        |> put_status(400)
        |> json(%{error: "Could not create key"})
        |> halt
    end
  end

  def revoke_key(conn, params) do
    case Keys.revoke_key(params) do
      :ok ->
        conn
        |> put_status(200)
        |> json(%{message: "Key revoked"})
        |> halt
      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "Could not revoke key"})
        |> halt
    end
  end
end
