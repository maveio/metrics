defmodule MaveMetricsWeb.VideoSocket do
  use Phoenix.Socket

  channel "session:*", MaveMetricsWeb.SessionChannel

  @impl true
  def connect(%{"source_url" => source_url} = _params, socket, connect_info) do
    ua = connect_info[:user_agent]

    {:ok,
     socket
     |> assign(:ua, UAInspector.parse(ua) |> session_info())
     |> assign(:source_url, source_url)}
  end

  @impl true
  def connect(_params, _socket, _connect_info) do
    {:error, :missing_params}
  end

  @impl true
  def id(_socket), do: nil

  defp session_info(%{os_family: platform, device: device, client: browser}) do
    %{
      browser_type: browser |> get_browser_type,
      platform: platform |> get_platform,
      device_type: device |> get_device
    }
  end

  defp get_browser_type(%{name: browser})
       when browser in ["Chrome Mobile", "Chrome Mobile iOS", "Chrome"],
       do: :chrome

  defp get_browser_type(%{name: browser})
       when browser in ["Firefox Mobile", "Firefox Mobile iOS", "Firefox"],
       do: :firefox

  defp get_browser_type(%{name: browser})
       when browser in ["Mobile Safari", "Safari Technology Preview", "Safari"],
       do: :safari

  defp get_browser_type(%{name: browser}) when browser in ["Opera Mobile", "Opera"], do: :opera
  defp get_browser_type(%{name: browser}) when browser in ["Edge Mobile", "Edge"], do: :edge

  defp get_browser_type(%{name: browser}) when browser in ["IE Mobile", "Internet Explorer"],
    do: :ie

  defp get_browser_type(%{name: browser}) when browser in ["Brave"], do: :brave
  defp get_browser_type(_browser), do: :other

  defp get_platform(platform) when platform in ["Windows", "Mac", "Linux", "iOS", "Android"],
    do: platform |> String.downcase() |> String.to_atom()

  defp get_platform(_platform), do: :other

  defp get_device(%{type: device}) when device == "smartphone", do: :mobile

  defp get_device(%{type: device}) when device in ["tablet", "desktop"],
    do: device |> String.to_atom()

  defp get_device(_device), do: :other
end
