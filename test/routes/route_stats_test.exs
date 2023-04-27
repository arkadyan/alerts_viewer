defmodule Routes.RouteStatsTest do
  use ExUnit.Case, async: true

  alias Routes.{Route, RouteStats}
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

  describe "vehicles_schedule_adherence_secs" do
    test "returns the vehicles_schedule_adherence_secs for RouteStats" do
      route_stats = %RouteStats{id: "1", vehicles_schedule_adherence_secs: [1, 2, 3]}

      assert RouteStats.vehicles_schedule_adherence_secs(route_stats) == [1, 2, 3]
    end

    test "returns the vehicles_schedule_adherence_secs for stats_by_route and a route" do
      secs = [1, 2, 3]
      stats_by_route = %{"1" => %RouteStats{id: "1", vehicles_schedule_adherence_secs: secs}}

      assert RouteStats.vehicles_schedule_adherence_secs(stats_by_route, %Route{id: "1"}) == secs
    end
  end

  describe "median_schedule_adherence" do
    test "returns the median schedule adherence for all vehicles rounded to 1 place" do
      route_stats = %RouteStats{id: "1", vehicles_schedule_adherence_secs: [1, 2, 3]}

      assert RouteStats.median_schedule_adherence(route_stats) == 2
    end

    test "returns nil if no vehicles_schedule_adherence_secs values" do
      route_stats = %RouteStats{id: "1", vehicles_schedule_adherence_secs: []}

      assert RouteStats.median_schedule_adherence(route_stats) == nil
    end

    test "accepts stats_by_route and a route" do
      stats_by_route = %{"1" => %RouteStats{id: "1", vehicles_schedule_adherence_secs: [1, 2, 3]}}

      assert RouteStats.median_schedule_adherence(stats_by_route, %Route{id: "1"}) == 2
    end
  end

  describe "standard_deviation_of_schedule_adherence rounded to 1 place" do
    test "" do
      route_stats = %RouteStats{id: "1", vehicles_schedule_adherence_secs: [1, 2]}

      assert RouteStats.standard_deviation_of_schedule_adherence(route_stats) == 0.5
    end

    test "returns nil if no vehicles_schedule_adherence_secs values" do
      route_stats = %RouteStats{id: "1", vehicles_schedule_adherence_secs: []}

      assert RouteStats.standard_deviation_of_schedule_adherence(route_stats) == nil
    end

    test "accepts stats_by_route and a route" do
      stats_by_route = %{"1" => %RouteStats{id: "1", vehicles_schedule_adherence_secs: [1, 2]}}

      assert RouteStats.standard_deviation_of_schedule_adherence(stats_by_route, %Route{id: "1"}) ==
               0.5
    end
  end

  describe "stats_for_route/2" do
    test "given stats_by_route, returns the stats for a single route" do
      route_stats = %RouteStats{id: "1", vehicles_schedule_adherence_secs: []}
      stats_by_route = %{"1" => route_stats}

      assert RouteStats.stats_for_route(stats_by_route, %Route{id: "1"}) == route_stats
    end

    test "returns an empty RouteStats struct if the requested route isn't found" do
      assert RouteStats.stats_for_route(%{}, %Route{id: "unknown"}) == %RouteStats{}
    end
  end
end
