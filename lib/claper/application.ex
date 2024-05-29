defmodule Claper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []
    {:ok, initial_state} = Lti_1p3.DataProviders.MemoryProvider.init()

    children = [
      {Cluster.Supervisor, [topologies, [name: Claper.ClusterSupervisor]]},
      # Start the Ecto repository
      Claper.Repo,
      # Start the Telemetry supervisor
      ClaperWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Claper.PubSub},
      # Start the Endpoint (http/https)
      ClaperWeb.Presence,
      ClaperWeb.Endpoint,
      # Start a worker by calling: Claper.Worker.start_link(arg)
      # {Claper.Worker, arg}
      {Finch, name: Swoosh.Finch},
      {Task.Supervisor, name: Claper.TaskSupervisor},
      {Lti_1p3.DataProviders.MemoryProvider, initial_state}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Claper.Supervisor]

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClaperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
