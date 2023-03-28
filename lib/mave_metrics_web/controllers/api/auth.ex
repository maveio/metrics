defmodule MaveMetricsWeb.API.Auth do
  use MaveMetricsWeb, :controller
  import Plug.Conn

  def require_api_authentication(conn, _opts) do
    case Plug.BasicAuth.parse_basic_auth(conn) do
      {user, password} ->
        conn |> handle_auth(user, password)
      _ ->
        conn |> unauthorized()
    end
  end

  defp handle_auth(conn, user, password) do
    if key_id == Application.get_env(:mave_metrics, :api_user) and
        secret == Application.get_env(:mave_metrics, :api_password) do
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
