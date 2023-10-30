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
    :scheduled_headway_secs,
    :instantaneous_headway_secs,
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
          scheduled_headway_secs: integer() | nil,
          instantaneous_headway_secs: integer() | nil,
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
      scheduled_headway_secs: rounded_or_nil(vehicle_position.scheduled_headway_secs),
      instantaneous_headway_secs: rounded_or_nil(vehicle_position.headway_secs),
      trip_id: vehicle_position.trip_id
    }
  end

  defp rounded_or_nil(nil), do: nil
  defp rounded_or_nil(secs) when is_number(secs), do: round(secs)

  @doc """
  Return the ID for the vehicle.

  iex> Vehicle.id(%Vehicle{id: "1234"})
  "1234"
  iex> Vehicle.id(%Vehicle{})
  ""
  iex> Vehicle.id(nil)
  ""
  """
  @spec id(t() | nil) :: String.t()
  def id(%__MODULE__{id: id}) when id != nil, do: id
  def id(_), do: ""

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
  Returns the schedule adherence in seconds for the vehicle.

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

  @doc """
  Returns the instantaneous headway in seconds for the vehicle.

  iex> Vehicle.instantaneous_headway_secs(%Vehicle{instantaneous_headway_secs: 24})
  24
  iex> Vehicle.instantaneous_headway_secs(%Vehicle{})
  nil
  """
  @spec instantaneous_headway_secs(t()) :: integer() | nil
  def instantaneous_headway_secs(%__MODULE__{
        instantaneous_headway_secs: instantaneous_headway_secs
      }),
      do: instantaneous_headway_secs

  def instantaneous_headway_secs(_),
    do: nil

  @doc """
  Returns the scheduled headway in seconds for the vehicle.

  iex> Vehicle.scheduled_headway_secs(%Vehicle{scheduled_headway_secs: 22})
  22
  iex> Vehicle.scheduled_headway_secs(%Vehicle{})
  nil
  """
  @spec scheduled_headway_secs(t()) :: integer() | nil
  def scheduled_headway_secs(%__MODULE__{
        scheduled_headway_secs: scheduled_headway_secs
      }),
      do: scheduled_headway_secs

  def scheduled_headway_secs(_),
    do: nil

  @doc """
  Returns the headway deviation (instantaneous - schedule headway) for a
  vehicle. If either of these values is missing, returns nil.

  iex> Vehicle.headway_deviation(%Vehicle{instantaneous_headway_secs: 25, scheduled_headway_secs: 22})
  3
  iex> Vehicle.headway_deviation(%Vehicle{instantaneous_headway_secs: nil, scheduled_headway_secs: 22})
  nil
  iex> Vehicle.headway_deviation(%Vehicle{instantaneous_headway_secs: 25, scheduled_headway_secs: nil})
  nil
  """
  @spec headway_deviation(t()) :: integer() | nil
  def headway_deviation(%__MODULE__{instantaneous_headway_secs: nil}), do: nil
  def headway_deviation(%__MODULE__{scheduled_headway_secs: nil}), do: nil

  def headway_deviation(%__MODULE__{
        instantaneous_headway_secs: instantaneous_headway_secs,
        scheduled_headway_secs: scheduled_headway_secs
      }),
      do: instantaneous_headway_secs - scheduled_headway_secs

  @doc """
  Returns whether or not the vehicle has a known headway deviation. This
  requires having a value for both the scheduled and instantaneus headway
  values.

  iex> Vehicle.headway_deviation?(%Vehicle{instantaneous_headway_secs: 25, scheduled_headway_secs: 22})
  true
  iex> Vehicle.headway_deviation?(%Vehicle{instantaneous_headway_secs: nil, scheduled_headway_secs: 22})
  false
  iex> Vehicle.headway_deviation?(%Vehicle{instantaneous_headway_secs: 25, scheduled_headway_secs: nil})
  false
  """
  @spec headway_deviation?(t()) :: boolean()
  def headway_deviation?(vehicle), do: !is_nil(headway_deviation(vehicle))
end
