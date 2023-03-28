defmodule MaveMetricsWeb.VideoSocket do
  use Phoenix.Socket

  channel "session:*", MaveMetricsWeb.SessionChannel

  @impl true
  def connect(%{"source_url" => source_url} = _params, socket, connect_info) do
    # TODO:
    # check if source_url is equal
    # to connect_info[:uri]

    ua = connect_info[:user_agent]

    {:ok, socket |> assign(:ua, ua) |> assign(:source_url, source_url)}
  end

  @impl true
  def connect(_params, _socket, _connect_info) do
    {:error, :missing_params}
  end

  @impl true
  def id(_socket), do: nil
end
