defmodule Vehicles.VehicleTest do
  use ExUnit.Case, async: true

  alias Vehicles.{Vehicle, VehiclePosition}

  doctest Vehicles.Vehicle

  @vehicle_position %VehiclePosition{
    bearing: 0,
    block_id: "S28-2",
    id: "y1261",
    last_updated: 1_558_364_020,
    latitude: 42.31777347,
    longitude: -71.08206019,
    operator_id: "72032",
    operator_last_name: "MAUPIN",
    run_id: "138-1038",
    layover_departure_time: nil,
    schedule_adherence_secs: 59,
    schedule_adherence_string: "59.0 sec (late)",
    speed: 0.0,
    stop_id: "392",
    trip_id: "39984755",
    direction_id: 1,
    route_id: "28"
  }

  describe "from_vehicle_position" do
    test "translates VehiclePosition into a Vehicle struct" do
      assert Vehicle.from_vehicle_position(@vehicle_position) == %Vehicle{
               id: "y1261",
               block_id: "S28-2",
               direction_id: 1,
               last_updated: 1_558_364_020,
               latitude: 42.31777347,
               longitude: -71.08206019,
               route_id: "28",
               run_id: "138-1038",
               schedule_adherence_secs: 59,
               schedule_adherence_string: "59.0 sec (late)",
               trip_id: "39984755"
             }
    end
  end
end
