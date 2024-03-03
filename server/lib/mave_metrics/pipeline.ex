defmodule MaveMetrics.Pipeline do
  use GenServer

  alias MaveMetrics.Stats

  @max_batch_size 50

  # 5 minutes
  @max_interval_ms 60_000 * 5

  def start_link(_) do
    GenServer.start_link(__MODULE__, {[], nil, false}, name: :pipeline, debug: [:log])
  end

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, opts, {:continue, :check_initial_conditions}}
  end

  @impl true
  def handle_continue(:check_initial_conditions, {events, timer_ref, aggregating}) do
    timer_ref =
      if events == [], do: Process.send_after(self(), :flush, @max_interval_ms), else: timer_ref

    {:noreply, {events, timer_ref, aggregating}}
  end

  # Handles adding events and checks for batch size threshold
  @impl true
  def handle_call({:add_event, event}, _pid, {events, timer_ref, aggregating}) do
    events = [event | events]

    timer_ref =
      if events == [event],
        do: Process.send_after(self(), :flush, @max_interval_ms),
        else: timer_ref

    if length(events) >= @max_batch_size do
      flush_events(events, timer_ref, aggregating)
      {:reply, :ok, {[], nil, aggregating}}
    else
      {:reply, :ok, {events, timer_ref, aggregating}}
    end
  end

  # Handles the scheduled flush message
  @impl true
  def handle_info(:flush, {events, timer_ref, aggregating}) do
    flush_events(events, timer_ref, aggregating)
    {:noreply, {[], nil, aggregating}}
  end

  @impl true
  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:start_aggregation, {events, timer_ref, false}) do
    pid = self()

    Task.start_link(fn ->
      Stats.refresh_daily_aggregation()
      GenServer.cast(pid, :aggregation_complete)
    end)

    {:noreply, {events, timer_ref, true}}
  end

  @impl true
  def handle_cast(:start_aggregation, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:aggregation_complete, {events, timer_ref, _}) do
    {:noreply, {events, timer_ref, false}}
  end

  # This function is called when the server is about to shut down
  @impl true
  def terminate(_reason, {events, timer_ref, aggregating}) do
    flush_events(events, timer_ref, aggregating)
  end

  # Helper function to flush events
  defp flush_events(events, timer_ref, _aggregating) when length(events) > 0 do
    Stats.create_events(events)
    GenServer.cast(self(), :start_aggregation)
    cancel_timer(timer_ref)
  end

  defp flush_events(_events, timer_ref, aggregating) do
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
