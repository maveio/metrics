defmodule MaveMetricsWeb.API.Auth do
  use MaveMetricsWeb, :controller
  import Plug.Conn

  def require_api_authenticated_user(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Base.decode64(token) do
          {:ok, token} ->
            [key_id, secret | _ ] = String.split(token, ":")
            conn |> handle_key(key_id, secret)
          _ ->
            conn |> unauthorized()
        end
      _ ->
        case Plug.BasicAuth.parse_basic_auth(conn) do
          {key_id, secret} ->
            conn |> handle_key(key_id, secret)
          _ ->
            conn |> unauthorized()
        end
    end
  end

  defp handle_key(conn, key_id, secret) do
    if key_id == Application.get_env(:mave_metrics, :api_key) and
        secret == Application.get_env(:mave_metrics, :api_secret) do
          conn
      else
        conn |> unauthorized()
    end
  end

  defp unauthorized(conn, reason \\ "You're not authorized to make this request") do
    conn
    |> put_status(401)
    |> json(%{error: reason})
    |> halt
  end
end
