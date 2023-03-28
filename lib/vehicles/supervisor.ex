defmodule Vehicles.Supervisor do
  @moduledoc """
  Supervisor for realtime Vehicle data. Fetches vehicle position data from Swiftly.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    swiftly_realtime_vehicles_url =
      Keyword.get(
        opts,
        :swiftly_realtime_vehicles_url,
        Application.get_env(:alerts_viewer, :swiftly_realtime_vehicles_url)
      )

    swiftly_authorization_key =
      Keyword.get(
        opts,
        :swiftly_authorization_key,
        Application.get_env(:alerts_viewer, :swiftly_authorization_key)
      )

    source =
      http_source(
        :swiftly_realtime_vehicles,
        swiftly_realtime_vehicles_url,
        Vehicles.Parser.SwiftlyRealtimeVehicles,
        headers: %{
          "Authorization" => swiftly_authorization_key
        },
        params: %{
          unassigned: "true",
          verbose: "true"
        }
      )

    consumer =
      Supervisor.child_spec(
        {Vehicles.VehiclePositions,
         subscribe_to: [{:swiftly_realtime_vehicles, [max_demand: 1]}]},
        []
      )

    Supervisor.init([source, consumer], strategy: :one_for_one)
  end

  @spec http_source(term(), String.t(), module(), keyword()) :: Supervisor.child_spec()
  defp http_source(source, url, parser, opts) do
    Supervisor.child_spec(
      {
        HttpProducer,
        {url, [name: source, parser: parser] ++ opts}
      },
      id: source
    )
  end
end
