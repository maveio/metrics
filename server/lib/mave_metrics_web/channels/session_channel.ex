defmodule MaveMetricsWeb.SessionChannel do
  use MaveMetricsWeb, :channel
  use Appsignal.Instrumentation.Decorators
  alias MaveMetricsWeb.Presence

  alias MaveMetrics.{Stats, Keys, Pipeline}

  @decorate channel_action()
  def join(
        "session:" <> _id,
        %{"metadata" => metadata, "key" => key} = params,
        %{id: _session_id, assigns: %{ua: ua}} = socket
      ) do
    case Keys.valid_key?(key) do
      {:ok, key} ->
        source_url = params["source_url"] || socket.assigns.source_url

        %{host: host, path: path} =
          source_url
          |> URI.parse()
          |> Map.take([:host, :path])

        # we're not storing the complete user-agent string to make it impossible to make a fingerprint
        session_attrs =
          %{uri_host: host, uri_path: path}
          |> Map.merge(ua)

        {:ok,
         socket
         |> assign(:session_attrs, session_attrs)
         |> assign(:session_id, nil)
         |> assign(:video_id, nil)
         |> assign(:key, key)
         |> assign(:metadata, metadata)}

      {:error, _reason} ->
        {:error, %{reason: "invalid key"}}
    end
  end

  @decorate channel_action()
  def join(_session, _params, _socket) do
    {:error, %{reason: "missing parameters and/or invalid host"}}
  end

  # initial play event
  @decorate channel_action()
  def handle_in(
        "event",
        %{"name" => "play", "from" => video_time} = params,
        %{
          assigns: %{
            session_attrs: session_attrs,
            session_id: session_id,
            video_id: video_id,
            metadata: metadata,
            key: key
          }
        } = socket
      )
      when is_nil(session_id) and is_nil(video_id) and not is_nil(video_time) do
    video_time = if is_binary(video_time), do: String.to_float(video_time), else: video_time

    # only create video and session once play starts
    {:ok, video} = Stats.find_or_create_video(key, metadata)
    {:ok, session} = Stats.create_session(video, session_attrs)

    Pipeline.add(%{
      type: :play,
      video_time: video_time,
      session_id: session.id,
      video_id: video.id,
      duration: params["duration"]
    })

    Presence.track(self(), "video:#{video.id}", "#{session.id}", %{})

    {
      :noreply,
      socket
      |> assign(:session_attrs, nil)
      |> assign(:metadata, nil)
      |> assign(:key, nil)
      |> assign(:session_id, session.id)
      |> assign(:video_id, video.id)
      |> assign(:duration, params["duration"])
      |> monitor(self())
    }
  end

  @decorate channel_action()
  def handle_in(
        "event",
        %{"name" => "play", "from" => video_time} = params,
        %{assigns: %{session_id: session_id, video_id: video_id}} = socket
      )
      when not is_nil(session_id) and not is_nil(video_id) and not is_nil(video_time) do
    video_time = if is_binary(video_time), do: String.to_float(video_time), else: video_time

    Pipeline.add(%{
      type: :play,
      video_time: video_time,
      session_id: session_id,
      video_id: video_id,
      timestamp: DateTime.utc_now(),
      duration: params["duration"]
    })

    Presence.track(self(), "video:#{video_id}", "#{session_id}", %{})

    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in(
        "event",
        %{"name" => "pause", "to" => video_time} = params,
        %{assigns: %{session_id: session_id, video_id: video_id}} = socket
      )
      when not is_nil(session_id) and not is_nil(video_id) and not is_nil(video_time) do
    video_time = if is_binary(video_time), do: String.to_float(video_time), else: video_time

    Pipeline.add(%{
      type: :pause,
      video_time: video_time,
      session_id: session_id,
      video_id: video_id,
      timestamp: DateTime.utc_now(),
      duration: params["duration"]
    })

    Presence.untrack(self(), "video:#{video_id}", "#{session_id}")

    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("event", _params, socket) do
    {:noreply, socket}
  end

  # https://github.com/phoenixframework/phoenix/issues/3844
  defp monitor(
         %{assigns: %{session_id: session_id, video_id: video_id, duration: duration}} = socket,
         pid
       ) do
    Task.Supervisor.start_child(MaveMetrics.TaskSupervisor, fn ->
      Process.flag(:trap_exit, true)
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, :process, _pid, _reason} ->
          on_disconnect(session_id, video_id, duration)
      end
    end)

    socket
  end

  defp on_disconnect(session_id, video_id, duration)
       when not is_nil(session_id) and not is_nil(video_id) do
    Pipeline.add(%{
      type: :disconnect,
      session_id: session_id,
      video_id: video_id,
      timestamp: DateTime.utc_now(),
      duration: duration
    })

    Presence.untrack(self(), "video:#{video_id}", "#{session_id}")
  end

  defp on_disconnect(_, _) do
    dbg("on_disconnect called with invalid session_id and video_id")
  end
end
