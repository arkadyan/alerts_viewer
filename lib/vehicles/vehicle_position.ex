defmodule Vehicles.VehiclePosition do
  @moduledoc """
  Structure for representing a transit vehicle's position.
  """

  defstruct [
    :id,
    :trip_id,
    :stop_id,
    :latitude,
    :longitude,
    :bearing,
    :speed,
    :block_id,
    :operator_id,
    :operator_last_name,
    :run_id,
    :last_updated,
    :stop_name,
    :direction_id,
    :headsign,
    :layover_departure_time,
    :previous_vehicle_id,
    :previous_vehicle_schedule_adherence_secs,
    :previous_vehicle_schedule_adherence_string,
    :route_id,
    :schedule_adherence_secs,
    :schedule_adherence_string,
    :sources,
    :data_discrepancies
  ]

  @type id :: String.t()

  @type direction_id :: 0 | 1

  @type t :: %__MODULE__{
          id: id(),
          trip_id: String.t(),
          stop_id: String.t(),
          latitude: float(),
          longitude: float(),
          bearing: number(),
          speed: number(),
          block_id: String.t(),
          operator_id: String.t(),
          operator_last_name: String.t(),
          run_id: String.t(),
          last_updated: non_neg_integer(),
          stop_name: String.t(),
          direction_id: direction_id(),
          headsign: String.t(),
          layover_departure_time: non_neg_integer(),
          previous_vehicle_id: String.t(),
          previous_vehicle_schedule_adherence_secs: number(),
          previous_vehicle_schedule_adherence_string: String.t(),
          route_id: String.t(),
          schedule_adherence_secs: number(),
          schedule_adherence_string: String.t()
        }

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
