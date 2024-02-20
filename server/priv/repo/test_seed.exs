# mix run priv/repo/test_seed.exs

alias MaveMetrics.Stats
alias MaveMetrics.Key
alias MaveMetrics.Repo

defmodule SeedScript do
  @browsers [:edge, :ie, :chrome, :firefox, :opera, :safari, :brave, :other]
  @platforms [:ios, :android, :mac, :windows, :linux, :other]
  @devices [:mobile, :tablet, :desktop, :other]
  @uri_hosts ["example.com", "localhost", "myapp.io", "site.test"]
  @uri_paths ["/home", "/about", "/contact", "/products", "/blog"]

  def run do
    # Ensure there is a Key entity for association
    key = Repo.insert!(%Key{key: "test_key"})

    # Define multiple video metadata entries
    video_metadatas = [
      %{"vid" => "a"},
      %{"vid" => "b"},
      %{"vid" => "c"},
      %{"vid" => "d"}
    ]

    Enum.each(video_metadatas, fn metadata ->
      # Create multiple videos linked to the Key
      {:ok, video} = Stats.find_or_create_video(key, metadata)

      # For each video, create a defined number of sessions
      number_of_sessions_per_video = 10000

      Enum.each(1..number_of_sessions_per_video, fn _session_index ->
        # Create a session linked to the video with random attributes
        {:ok, session} = create_session_with_video_and_random_attributes(video)

        # Generate dynamic play and pause events for each session
        create_dynamic_play_pause_events(session.id, video.id)
      end)
    end)

    IO.puts(
      "Successfully created sessions and events for multiple videos with diverse attributes."
    )
  end

  defp create_session_with_video_and_random_attributes(video) do
    random_attrs = %{
      browser: Enum.random(@browsers),
      platform: Enum.random(@platforms),
      device: Enum.random(@devices),
      uri_host: Enum.random(@uri_hosts),
      uri_path: Enum.random(@uri_paths),
      timestamp: DateTime.utc_now()
    }

    Stats.create_session(video, random_attrs)
  end

  defp create_dynamic_play_pause_events(session_id, video_id) do
    # Random start time between 0 and 300 seconds
    play_time = Enum.random(0..300)
    # Random duration between 1 and 10 minutes
    duration = Enum.random(60..600)
    pause_time = play_time + duration

    play_event_attrs = %{
      "type" => :play,
      "timestamp" => DateTime.utc_now(),
      "video_time" => play_time,
      "session_id" => session_id,
      "video_id" => video_id
    }

    Stats.create_event(play_event_attrs)

    pause_event_attrs = %{
      "type" => :pause,
      "timestamp" => DateTime.add(DateTime.utc_now(), duration, :second),
      "video_time" => pause_time,
      "session_id" => session_id,
      "video_id" => video_id
    }

    Stats.create_event(pause_event_attrs)
  end
end

# To execute the script, run:
SeedScript.run()
