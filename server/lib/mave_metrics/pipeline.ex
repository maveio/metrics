defmodule MaveMetrics.Pipeline do
  use GenServer

  alias MaveMetrics.Stats

  @max_batch_size 2

  # 5 minutes
  @max_interval_ms 60_000 * 5

  def start_link(_) do
    GenServer.start_link(__MODULE__, {[], nil}, name: :pipeline, debug: [:log])
  end

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, opts, {:continue, :check_initial_conditions}}
  end

  @impl true
  def handle_continue(:check_initial_conditions, {events, timer_ref}) do
    timer_ref =
      if events == [], do: Process.send_after(self(), :flush, @max_interval_ms), else: timer_ref

    {:noreply, {events, timer_ref}}
  end

  # Handles adding events and checks for batch size threshold
  @impl true
  def handle_call({:add_event, event}, _pid, {events, timer_ref}) do
    events = [event | events]

    timer_ref =
      if events == [event],
        do: Process.send_after(self(), :flush, @max_interval_ms),
        else: timer_ref

    if length(events) >= @max_batch_size do
      flush_events(events, timer_ref)
      {:reply, :ok, {[], nil}}
    else
      {:reply, :ok, {events, timer_ref}}
    end
  end

  # Handles the scheduled flush message
  @impl true
  def handle_info(:flush, {events, timer_ref}) do
    flush_events(events, timer_ref)
    {:noreply, {[], nil}}
  end

  # This function is called when the server is about to shut down
  @impl true
  def terminate(:shutdown, {events, timer_ref}) do
    flush_events(events, timer_ref)
  end

  # Helper function to flush events
  defp flush_events(events, timer_ref) when length(events) > 0 do
    Stats.create_events(events)
    cancel_timer(timer_ref)
  end

  defp flush_events(_events, timer_ref) do
    cancel_timer(timer_ref)
  end

  defp cancel_timer(timer_ref) do
    if !is_nil(timer_ref), do: Process.cancel_timer(timer_ref)
  end

  # Public API to add an event
  def add(event) do
    event =
      if Map.has_key?(event, :timestamp) do
        event
      else
        Map.put(event, :timestamp, DateTime.utc_now())
      end

    pid = GenServer.whereis(:pipeline)
    GenServer.call(pid, {:add_event, event})

    event
  end
end
