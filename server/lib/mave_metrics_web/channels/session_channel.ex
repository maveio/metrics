defmodule MaveMetricsWeb.SessionChannel do
  use MaveMetricsWeb, :channel

  alias MaveMetrics.{Stats, Keys, Pipeline}

  @impl true
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
         |> assign(:key, key)
         |> assign(:metadata, metadata)}

      {:error, _reason} ->
        {:error, %{reason: "invalid key"}}
    end
  end

  @impl true
  def join(_session, _params, _socket) do
    {:error, %{reason: "missing parameters and/or invalid host"}}
  end

  @impl true
  def handle_in(
        "event",
        %{"name" => "play", "from" => from},
        %{
          assigns: %{
            session_attrs: session_attrs,
            session_id: session_id,
            metadata: metadata,
            key: key
          }
        } = socket
      )
      when is_nil(session_id) do
    # only create video and session once play starts
    {:ok, video} = Stats.find_or_create_video(key, metadata)
    {:ok, session} = Stats.create_session(video, session_attrs)

    Pipeline.add(%{
      type: :play,
      video_time: from,
      session_id: session.id
    })

    {
      :noreply,
      socket
      |> assign(:session_attrs, nil)
      |> assign(:metadata, nil)
      |> assign(:key, nil)
      |> assign(:session_id, session.id)
      |> monitor(self())
    }
  end

  @impl true
  def handle_in(
        "event",
        %{"name" => "play", "from" => from},
        %{assigns: %{session_id: session_id}} = socket
      ) do
    Pipeline.add(%{
      type: :play,
      video_time: from,
      session_id: session_id
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "event",
        %{"name" => "pause", "to" => to},
        %{assigns: %{session_id: session_id}} = socket
      ) do
    Pipeline.add(%{
      type: :pause,
      video_time: to,
      session_id: session_id
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("event", _params, socket) do
    {:noreply, socket}
  end

  # https://github.com/phoenixframework/phoenix/issues/3844
  defp monitor(%{assigns: %{session_id: session_id}} = socket, pid) do
    Task.Supervisor.start_child(MaveMetrics.TaskSupervisor, fn ->
      Process.flag(:trap_exit, true)
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, :process, _pid, _reason} ->
          on_disconnect(session_id)
      end
    end)

    socket
  end

  defp on_disconnect(session_id) do
    Pipeline.add(%{
      type: :disconnect,
      session_id: session_id
    })
  end
end
