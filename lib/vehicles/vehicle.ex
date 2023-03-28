defmodule Vehicles.Vehicle do
  @moduledoc """
  Representation of a transit vehicle.
  """

  alias Routes.Route
  alias Vehicles.VehiclePosition

  defstruct [
    :id,
    :block_id,
    :direction_id,
    :last_updated,
    :latitude,
    :longitude,
    :route_id,
    :run_id,
    :schedule_adherence_secs,
    :schedule_adherence_string,
    :trip_id
  ]

  @type id :: String.t()

  @type direction_id :: 0 | 1

  @type t :: %__MODULE__{
          id: id(),
          block_id: String.t(),
          direction_id: direction_id(),
          last_updated: non_neg_integer(),
          latitude: float(),
          longitude: float(),
          route_id: Route.id(),
          run_id: String.t(),
          schedule_adherence_secs: integer(),
          schedule_adherence_string: String.t(),
          trip_id: String.t()
        }

  @spec from_vehicle_position(VehiclePosition.t()) :: t()
  def from_vehicle_position(vehicle_position) do
    %__MODULE__{
      id: vehicle_position.id,
      block_id: vehicle_position.block_id,
      direction_id: vehicle_position.direction_id,
      last_updated: vehicle_position.last_updated,
      latitude: vehicle_position.latitude,
      longitude: vehicle_position.longitude,
      route_id: vehicle_position.route_id,
      run_id: vehicle_position.run_id,
      schedule_adherence_secs: round(vehicle_position.schedule_adherence_secs),
      schedule_adherence_string: vehicle_position.schedule_adherence_string,
      trip_id: vehicle_position.trip_id
    }
  end

  @doc """
  Returns whether or noth the vehicle has a route ID.

  iex> Vehicle.route_id?(%Vehicle{route_id: "39"})
  true
  iex> Vehicle.route_id?(%Vehicle{route_id: nil})
  false
  iex> Vehicle.route_id?(%Vehicle{})
  false
  """
  @spec route_id?(t()) :: boolean()
  def route_id?(%__MODULE__{route_id: route_id}) when not is_nil(route_id), do: true
  def route_id?(_), do: false

  @doc """
  Returns the route ID for the vehicle.

  iex> Vehicle.route_id(%Vehicle{route_id: "39"})
  "39"
  iex> Vehicle.route_id(%Vehicle{})
  nil
  """
  @spec route_id(t()) :: Route.id() | nil
  def route_id(%__MODULE__{route_id: route_id}), do: route_id
  def route_id(_), do: nil

  @doc """
  Returns the route ID for the vehicle.

  iex> Vehicle.schedule_adherence_secs(%Vehicle{schedule_adherence_secs: 42})
  42
  iex> Vehicle.schedule_adherence_secs(%Vehicle{})
  nil
  """
  @spec schedule_adherence_secs(t()) :: integer() | nil
  def schedule_adherence_secs(%__MODULE__{schedule_adherence_secs: schedule_adherence_secs}),
    do: schedule_adherence_secs

  def schedule_adherence_secs(_),
    do: nil
end
