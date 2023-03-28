defmodule Vehicles.VehiclePositionTest do
  use ExUnit.Case, async: true

  alias Vehicles.VehiclePosition

  describe "new/1" do
    test "constructs a new VehiclePosition struct from the input fields" do
      fields = %{
        id: "y1714",
        latitude: 42.31914,
        longitude: -71.10337,
        speed: 11,
        bearing: 33,
        stop_id: "23391",
        trip_id: "39998535",
        block_id: "B36-173",
        run_id: "122-1065",
        operator_id: "71924",
        operator_last_name: "PAUL",
        last_updated: 1_559_672_827,
        stop_name: "Back Bay",
        direction_id: 0,
        headsign: "Forest Hills",
        layover_departure_time: 1_559_673_780,
        previous_vehicle_id: "y1272",
        previous_vehicle_schedule_adherence_secs: 59,
        previous_vehicle_schedule_adherence_string: "59.0 sec (late)",
        route_id: "39",
        schedule_adherence_secs: 0,
        schedule_adherence_string: "0.0 sec (ontime)"
      }

      assert %VehiclePosition{} = VehiclePosition.new(fields)
    end
  end
end
