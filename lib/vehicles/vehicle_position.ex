defmodule Vehicles.VehiclePosition do
  @moduledoc """
  Structure for representing a transit vehicle's position.
  """

  defstruct [
    :id,
    :bearing,
    :block_id,
    :direction_id,
    :headsign,
    :headway_secs,
    :last_updated,
    :layover_departure_time,
    :latitude,
    :longitude,
    :operator_id,
    :operator_last_name,
    :previous_vehicle_id,
    :previous_vehicle_schedule_adherence_secs,
    :previous_vehicle_schedule_adherence_string,
    :route_id,
    :run_id,
    :schedule_adherence_secs,
    :schedule_adherence_string,
    :scheduled_headway_secs,
    :speed,
    :stop_id,
    :stop_name,
    :trip_id
  ]

  @type id :: String.t()

  @type direction_id :: 0 | 1

  @type t :: %__MODULE__{
          id: id(),
          bearing: number(),
          block_id: String.t(),
          direction_id: direction_id(),
          headway_secs: number() | nil,
          headsign: String.t(),
          last_updated: non_neg_integer(),
          layover_departure_time: non_neg_integer(),
          latitude: float(),
          longitude: float(),
          operator_id: String.t(),
          operator_last_name: String.t(),
          previous_vehicle_id: String.t(),
          previous_vehicle_schedule_adherence_secs: number(),
          previous_vehicle_schedule_adherence_string: String.t(),
          route_id: String.t(),
          run_id: String.t(),
          schedule_adherence_secs: number(),
          schedule_adherence_string: String.t(),
          scheduled_headway_secs: number(),
          speed: number(),
          stop_id: String.t(),
          stop_name: String.t(),
          trip_id: String.t()
        }

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
