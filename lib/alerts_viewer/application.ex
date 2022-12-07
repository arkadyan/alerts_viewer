defmodule AlertsViewer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    load_runtime_config()

    children =
      if Application.get_env(:alerts_viewer, :start_data_processes) do
        [
          Alerts.Supervisor
        ]
      else
        []
      end ++
        [
          # Start the Telemetry supervisor
          AlertsViewerWeb.Telemetry,
          # Start the PubSub system
          {Phoenix.PubSub, name: AlertsViewer.PubSub},
          # Start Finch
          {Finch, name: AlertsViewer.Finch},
          # Start the Endpoint (http/https)
          AlertsViewerWeb.Endpoint
          # Start a worker by calling: AlertsViewer.Worker.start_link(arg)
          # {AlertsViewer.Worker, arg}
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlertsViewer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlertsViewerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @doc """
  Check system environment variables at runtime and load them into the application environment.

  Will recursively check the keys below in the application config for any {:system, "ENVIRONMENT_VARIABLE"},
  and replace them with the value in the given environment variable.

  """
  @spec load_runtime_config() :: :ok
  def load_runtime_config() do
    application_keys = [
      :api_url,
      :api_key
    ]

    for application_key <- application_keys do
      Application.put_env(
        :alerts_viewer,
        application_key,
        runtime_config(Application.get_env(:alerts_viewer, application_key))
      )
    end

    :ok
  end

  @spec runtime_config(any()) :: any()
  defp runtime_config(list) when is_list(list) do
    Enum.map(list, fn elem ->
      case elem do
        {key, value} when is_atom(key) ->
          {key, runtime_config(value)}

        _ ->
          elem
      end
    end)
  end

  defp runtime_config({:system, environment_variable}) do
    System.get_env(environment_variable)
  end

  defp runtime_config(value) do
    value
  end
end
