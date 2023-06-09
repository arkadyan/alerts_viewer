defmodule Vehicles.VehiclePositionTest do
  use ExUnit.Case, async: true

  alias Vehicles.VehiclePosition

  describe "new/1" do
    test "constructs a new VehiclePosition struct from the input fields" do
      fields = %{
        id: "y1714",
        bearing: 33,
        block_id: "B36-173",
        direction_id: 0,
        headsign: "Forest Hills",
        headway_secs: 2889.665,
        last_updated: 1_559_672_827,
        latitude: 42.31914,
        layover_departure_time: 1_559_673_780,
        longitude: -71.10337,
        operator_id: "71924",
        operator_last_name: "PAUL",
        previous_vehicle_id: "y1272",
        previous_vehicle_schedule_adherence_secs: 59,
        previous_vehicle_schedule_adherence_string: "59.0 sec (late)",
        route_id: "39",
        run_id: "122-1065",
        schedule_adherence_secs: 0,
        schedule_adherence_string: "0.0 sec (ontime)",
        scheduled_headway_secs: 2340,
        speed: 11,
        stop_id: "23391",
        stop_name: "Back Bay",
        trip_id: "39998535"
      }

      assert %VehiclePosition{} = VehiclePosition.new(fields)
    end
  end
end
