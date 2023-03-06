defmodule MaveMetrics.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MaveMetricsWeb.Telemetry,
      # Start the Ecto repository
      MaveMetrics.Repo,
      # Start UAInspector
      UAInspector.Supervisor,
      # Start supervisor
      {Task.Supervisor, name: MaveMetrics.TaskSupervisor},
      # Start the PubSub system
      {Phoenix.PubSub, name: MaveMetrics.PubSub},
      # Start Finch
      {Finch, name: MaveMetrics.Finch},
      # Start the Endpoint (http/https)
      MaveMetricsWeb.Endpoint
      # Start a worker by calling: MaveMetrics.Worker.start_link(arg)
      # {MaveMetrics.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MaveMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MaveMetricsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
