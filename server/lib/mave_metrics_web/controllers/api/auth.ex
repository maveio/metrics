defmodule MaveMetricsWeb.API.Auth do
  use MaveMetricsWeb, :controller
  import Plug.Conn

  def require_api_authentication?(conn, _opts) do
    unless Application.get_env(:mave_metrics, :api_auth) do
      conn
    else
      with {user, pass} <- Plug.BasicAuth.parse_basic_auth(conn),
          true <- handle_auth(user, pass) do
        conn
      else
        _ -> conn |> Plug.BasicAuth.request_basic_auth() |> halt()
      end
    end
  end

  defp handle_auth(user, password), do: user == Application.get_env(:mave_metrics, :api_user) and password == Application.get_env(:mave_metrics, :api_password)
end
