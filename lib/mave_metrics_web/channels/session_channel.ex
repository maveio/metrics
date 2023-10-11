defmodule MaveMetricsWeb.SessionChannel do
  use MaveMetricsWeb, :channel

  alias MaveMetrics.Stats
  alias MaveMetrics.Keys

  @impl true
  def join(
        "session:" <> _id,
        %{"identifier" => identifier, "key" => key} = params,
        %{id: _session_id, assigns: %{ua: ua}} = socket
      ) do
    with %UAInspector.Result.Bot{name: _name} <- UAInspector.parse(ua) do
      {:error, %{reason: "bot"}}
    else
      parsed_ua ->
        case Keys.valid_key?(key) do
          {:ok, key} ->
            source_url = params["source_url"] || socket.assigns.source_url

            # we're not storing the complete user-agent string to make it impossible to make a fingerprint
            session_attrs =
              %{
                metadata: params["session_data"]
              }
              |> Map.merge(parsed_ua |> session_info())

            {:ok, video} = Stats.find_or_create_video(source_url, identifier, params["metadata"])

            {:ok, session} = Stats.create_session(video, key, session_attrs)
            {:ok, socket |> assign(:session_id, session.id) |> monitor(self())}

          {:error, _reason} ->
            {:error, %{reason: "invalid key"}}
        end
    end
  end

  @impl true
  def join(_session, _params, _socket) do
    {:error, %{reason: "missing parameters and/or invalid host"}}
  end

  @impl true
  def handle_in(
        "event",
        %{"name" => "play", "from" => from, "timestamp" => timestamp} = params,
        %{assigns: %{session_id: session_id}} = socket
      ) do
    create_event(params, socket)

    timestamp = DateTime.from_unix!(timestamp, :millisecond)

    Stats.create_duration(%{
      from: from,
      session_id: session_id,
      timestamp: timestamp
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "event",
        %{"name" => "pause", "to" => to} = params,
        %{assigns: %{session_id: session_id}} = socket
      ) do
    create_event(params, socket)

    duration = Stats.get_last_duration(session_id)

    if duration do
      Stats.update_duration(duration, %{
        to: to,
        elapsed_time: to - duration.from
      })
    end

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "event",
        %{"name" => "rebuffering_start", "from" => from, "timestamp" => timestamp} = params,
        %{assigns: %{session_id: session_id}} = socket
      ) do
    create_event(params, socket)

    timestamp = DateTime.from_unix!(timestamp, :millisecond)

    Stats.create_duration(%{
      from: from,
      session_id: session_id,
      timestamp: timestamp,
      type: :rebuffering
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "event",
        %{"name" => "rebuffering_end", "timestamp" => timestamp} = params,
        %{assigns: %{session_id: session_id}} = socket
      ) do
    create_event(params, socket)
    duration = Stats.get_last_duration(session_id, :rebuffering)

    if duration do
      to = DateTime.from_unix!(timestamp, :millisecond)
      elapsed_time = DateTime.diff(to, duration.timestamp, :millisecond) / 1000

      Stats.update_rebuffering(duration, elapsed_time)
    end

    {:noreply, socket}
  end

  # TODO:
  # implement fullscreen_enter, fullscreen_exit duration

  @impl true
  def handle_in(
        "event",
        %{"name" => "track_set", "language" => language, "timestamp" => timestamp} = params,
        %{assigns: %{session_id: session_id}} = socket
      ) do
    create_event(params, socket)

    timestamp = DateTime.from_unix!(timestamp, :millisecond)

    Stats.create_track(%{
      language: language,
      session_id: session_id,
      timestamp: timestamp
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("event", params, socket) do
    create_event(params, socket)
    {:noreply, socket}
  end

  defp create_event(%{"name" => name, "timestamp" => timestamp}, %{
         assigns: %{session_id: session_id}
       }) do
    timestamp = DateTime.from_unix!(timestamp, :millisecond)

    Stats.create_event(%{
      name: name,
      timestamp: timestamp,
      session_id: session_id
    })
  end

  # https://github.com/phoenixframework/phoenix/issues/3844
  defp monitor(socket, pid) do
    Task.Supervisor.start_child(MaveMetrics.TaskSupervisor, fn ->
      Process.flag(:trap_exit, true)
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, :process, _pid, _reason} ->
          on_disconnect(socket)
      end
    end)

    socket
  end

  defp on_disconnect(%{assigns: %{session_id: session_id}} = _socket) do
    with true <- Stats.duration_not_closed?(:play, session_id),
         %{timestamp: timestamp, from: from} = duration <- Stats.get_last_duration(session_id) do
      now = DateTime.utc_now()
      elapsed_time = DateTime.diff(now, timestamp)
      to = from + elapsed_time

      Stats.update_duration(duration, %{to: to, elapsed_time: elapsed_time})

      Stats.create_event(%{
        name: :pause,
        timestamp: timestamp,
        session_id: session_id
      })
    else
      _ -> nil
    end

    with true <- Stats.duration_not_closed?(:rebuffering_start, session_id),
         %{timestamp: timestamp} = duration <- Stats.get_last_duration(session_id, :rebuffering) do
      now = DateTime.utc_now()
      elapsed_time = DateTime.diff(now, timestamp)

      Stats.update_rebuffering(duration, elapsed_time)

      Stats.create_event(%{
        name: :rebuffering_end,
        timestamp: timestamp,
        session_id: session_id
      })
    else
      _ -> nil
    end
  end

  defp on_disconnect(_socket), do: nil

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
