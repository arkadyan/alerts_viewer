defmodule Routes.RouteStats do
  @moduledoc """
  Describe a collection of stats for the current state of a route.
  """

  alias Routes.Route
  alias Vehicles.Vehicle

  defstruct [
    :id,
    vehicles_schedule_adherence_secs: []
  ]

  @type t :: %__MODULE__{
          id: Route.id(),
          vehicles_schedule_adherence_secs: [integer()]
        }

  @type stats_by_route() :: %{Route.id() => t()}

  @spec from_vehicles(Route.id(), [Vehicle.t()]) :: t()
  def from_vehicles(route_id, vehicles) do
    %__MODULE__{
      id: route_id,
      vehicles_schedule_adherence_secs: schedule_adherence_secs_of_vehicles(vehicles)
    }
  end

  @spec vehicles_schedule_adherence_secs(t()) :: [integer()]
  @spec vehicles_schedule_adherence_secs(stats_by_route(), Route.t()) :: [integer()]
  def vehicles_schedule_adherence_secs(%__MODULE__{
        vehicles_schedule_adherence_secs: vehicles_schedule_adherence_secs
      }),
      do: vehicles_schedule_adherence_secs

  def vehicles_schedule_adherence_secs(stats_by_route, route) do
    stats_by_route
    |> stats_for_route(route)
    |> vehicles_schedule_adherence_secs()
  end

  @spec median_schedule_adherence(t()) :: number() | nil
  @spec median_schedule_adherence(stats_by_route(), Route.t()) :: number() | nil
  def median_schedule_adherence(route_stats) do
    route_stats
    |> vehicles_schedule_adherence_secs()
    |> Statistics.median()
    |> round_to_1_place()
  end

  def median_schedule_adherence(stats_by_route, route) do
    stats_by_route
    |> stats_for_route(route)
    |> median_schedule_adherence()
  end

  @spec standard_deviation_of_schedule_adherence(t()) ::
          number() | nil
  @spec standard_deviation_of_schedule_adherence(stats_by_route(), Route.t()) ::
          number() | nil
  def standard_deviation_of_schedule_adherence(route_stats) do
    route_stats
    |> vehicles_schedule_adherence_secs()
    |> Statistics.stdev()
    |> round_to_1_place()
  end

  def standard_deviation_of_schedule_adherence(stats_by_route, route) do
    stats_by_route
    |> stats_for_route(route)
    |> standard_deviation_of_schedule_adherence()
  end

  @spec stats_for_route(stats_by_route(), Route.t()) :: t()
  def stats_for_route(stats_by_route, %Route{id: route_id}),
    do: Map.get(stats_by_route, route_id, %__MODULE__{})

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

  @spec round_to_1_place(number() | nil) :: number() | nil
  defp round_to_1_place(int) when is_integer(int), do: int
  defp round_to_1_place(num) when is_number(num), do: Float.round(num, 1)
  defp round_to_1_place(_), do: nil
end
