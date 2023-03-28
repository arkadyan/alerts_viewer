defmodule Vehicles.VehiclePositions do
  @moduledoc """
  Consumes output from the swiftly_realtime_vehicles HTTP producer and reports vehicle positions to the realtime server.
  """

  use GenStage

  alias Routes.RouteStatsPubSub
  alias Vehicles.Vehicle

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    {:consumer, :the_state_does_not_matter, opts}
  end

  # If we get a reply after we've already timed out, ignore it
  @impl GenStage
  def handle_info({reference, _}, state) when is_reference(reference),
    do: {:noreply, [], state}

  @impl GenStage
  def handle_events([vehicle_positions], _from, state) do
    vehicle_positions
    |> Enum.map(&Vehicle.from_vehicle_position/1)
    |> group_by_route()
    |> RouteStatsPubSub.update_stats()

    {:noreply, [], state}
  end

  @spec group_by_route([Vehicle.t()]) :: RouteStatsPubSub.vehicles_by_route()
  defp group_by_route(vehicles) do
    vehicles
    |> Enum.filter(&Vehicle.route_id?/1)
    |> Enum.group_by(&Vehicle.route_id/1)
  end
end
