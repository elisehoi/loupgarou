defmodule Loupgarou.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LoupgarouWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:loupgarou, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Loupgarou.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Loupgarou.Finch},
      # Start a worker by calling: Loupgarou.Worker.start_link(arg)
      # {Loupgarou.Worker, arg},
      # Start to serve requests, typically the last entry
      LoupgarouWeb.Endpoint,
      Loupgarou.GameLogic.GameProcess
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Loupgarou.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LoupgarouWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
