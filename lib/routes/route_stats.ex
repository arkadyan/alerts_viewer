defmodule Routes.RouteStats do
  @moduledoc """
  Describe a collection of stats for the current state of a route.
  """

  alias Routes.Route
  alias Vehicles.Vehicle

  defstruct [
    :id,
    :vehicles_schedule_adherence_secs
  ]

  @type t :: %__MODULE__{
          id: Route.id(),
          vehicles_schedule_adherence_secs: [integer()]
        }

  @spec from_vehicles(Route.id(), [Vehicle.t()]) :: t()
  def from_vehicles(route_id, vehicles) do
    %__MODULE__{
      id: route_id,
      vehicles_schedule_adherence_secs: schedule_adherence_secs_of_vehicles(vehicles)
    }
  end

  @spec vehicles_schedule_adherence_secs(t()) :: [integer()]
  def vehicles_schedule_adherence_secs(%__MODULE__{
        vehicles_schedule_adherence_secs: vehicles_schedule_adherence_secs
      }),
      do: vehicles_schedule_adherence_secs

  @spec schedule_adherence_secs_of_vehicles([Vehicle.t()]) :: [integer()]
  defp schedule_adherence_secs_of_vehicles(vehicles) do
    Enum.reduce(vehicles, [], fn vehicle, acc ->
      case Vehicle.schedule_adherence_secs(vehicle) do
        nil ->
          acc

        secs ->
          [secs | acc]
      end
    end)
  end
end
