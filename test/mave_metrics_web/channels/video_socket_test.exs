defmodule MaveMetricsWeb.VideoSocketTest do
  use MaveMetricsWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      VideoSocket
      |> socket("session_id", %{some: :assign})
      |> subscribe_and_join(MaveMetricsWeb.SessionChannel, "video:lobby")

    %{socket: socket}
  end

  test "ping", %{socket: socket} do
    dbg socket
  end
end
