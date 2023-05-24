defmodule MaveMetricsWeb.API.Auth do
  use MaveMetricsWeb, :controller
  import Plug.Conn

  def require_api_authentication(conn, _opts) do
    if !Application.get_env(:mave_metrics, :api_auth) do
      conn
    else
      case get_req_header(conn, "Authorization") do
        ["Token " <> token] ->
          case Base.decode64(token) do
            {:ok, token} ->
              [user, password | _ ] = String.split(token, ":")
              conn |> handle_auth(user, password)
            _ ->
              conn |> unauthorized()
          end
        _ ->
          conn |> unauthorized()
      end
    end
  end

  defp handle_auth(conn, user, password) do
    if user == Application.get_env(:mave_metrics, :api_user) and
        password == Application.get_env(:mave_metrics, :api_password) do
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
