defmodule Routes.RouteStatsTest do
  use ExUnit.Case, async: true

  alias Routes.RouteStats
  alias Vehicles.Vehicle

  describe "from_vehicles/2" do
    test "constructs a RouteStats struct from a list of Vehicles" do
      vehicles = [
        %Vehicle{schedule_adherence_secs: 10},
        %Vehicle{schedule_adherence_secs: 20}
      ]

      assert RouteStats.from_vehicles("66", vehicles) == %RouteStats{
               id: "66",
               vehicles_schedule_adherence_secs: [20, 10]
             }
    end
  end
end
