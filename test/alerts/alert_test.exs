defmodule Alerts.AlertTest do
  use ExUnit.Case, async: true

  alias Alerts.Alert

  describe "entities_with_icons" do
    test "returns a list of route IDs or facility activities representing the alert's informed entities" do
      alert = %Alert{
        id: "1",
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3},
          %{activities: [:using_wheelchair, :park_car, :board], facility: "772", stop: "70511"}
        ]
      }

      assert Alert.entities_with_icons(alert) == ["28", "using_wheelchair", "park_car"]
    end

    test "returns only unique results" do
      alert = %Alert{
        id: "1",
        informed_entity: [
          %{activities: [:board], route: "28", route_type: 3},
          %{activities: [:exit], route: "28", route_type: 3}
        ]
      }

      assert Alert.entities_with_icons(alert) == ["28"]
    end

    test "combines bike activities" do
      alert = %Alert{
        id: "1",
        informed_entity: [
          %{activities: [:bringing_bike, :store_bike], facility: "772", stop: "70511"}
        ]
      }

      assert Alert.entities_with_icons(alert) == ["bike"]
    end
  end

  describe "matches_service_type" do
    test "matches by route type" do
      bus_alert = %Alert{
        id: "1",
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ]
      }

      access_alert = %Alert{
        id: "2",
        informed_entity: [
          %{activities: [:using_wheelchair, :park_car], facility: "772", stop: "70511"}
        ]
      }

      assert Alert.matches_service_type(bus_alert, 3)
      refute Alert.matches_service_type(access_alert, 3)
    end

    test "matches by access service types" do
      bringing_bike_alert = %Alert{
        id: "2",
        informed_entity: [
          %{activities: [:bringing_bike], facility: "772", stop: "70511"}
        ]
      }

      park_car_alert = %Alert{
        id: "2",
        informed_entity: [
          %{activities: [:park_car], facility: "772", stop: "70511"}
        ]
      }

      store_bike_alert = %Alert{
        id: "2",
        informed_entity: [
          %{activities: [:store_bike], facility: "772", stop: "70511"}
        ]
      }

      using_escalator_alert = %Alert{
        id: "2",
        informed_entity: [
          %{activities: [:using_escalator], facility: "772", stop: "70511"}
        ]
      }

      using_wheelchair_alert = %Alert{
        id: "2",
        informed_entity: [
          %{activities: [:using_wheelchair], facility: "772", stop: "70511"}
        ]
      }

      bus_alert = %Alert{
        id: "1",
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ]
      }

      assert Alert.matches_service_type(bringing_bike_alert, :access)
      assert Alert.matches_service_type(park_car_alert, :access)
      assert Alert.matches_service_type(store_bike_alert, :access)
      assert Alert.matches_service_type(using_escalator_alert, :access)
      assert Alert.matches_service_type(using_wheelchair_alert, :access)
      refute Alert.matches_service_type(bus_alert, :access)
    end
  end

  describe "matches_route/2" do
    test "matches by informed entity routes" do
      a28 = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ]
      }

      a69 = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "69", route_type: 3}
        ]
      }

      assert Alert.matches_route(a28, "28")
      refute Alert.matches_route(a69, "28")
    end
  end

  describe "matches_effect/2" do
    test "matches by effect type" do
      delay_affect = %Alert{effect: :delay}
      detour_affect = %Alert{effect: :detour}

      assert Alert.matches_effect(delay_affect, :delay)
      refute Alert.matches_effect(detour_affect, :delay)
    end
  end

  describe "matches_route_and_effect/3" do
    test "matches by informed entity routes and effect type" do
      a28_delay = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ],
        effect: :delay
      }

      a28_detour = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ],
        effect: :detour
      }

      a69_delay = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "69", route_type: 3}
        ],
        effect: :delay
      }

      assert Alert.matches_route_and_effect(a28_delay, "28", :delay)
      refute Alert.matches_route_and_effect(a28_detour, "28", :delay)
      refute Alert.matches_route_and_effect(a69_delay, "28", :delay)
    end
  end

  describe "alert_duration/2" do
    test "returns duration of alert in seconds" do
      current_time = DateTime.new!(~D[2023-07-21], ~T[09:26:08.003], "America/New_York")

      alert = %Alert{
        id: 1,
        severity: 3,
        created_at: DateTime.add(current_time, -90, :minute),
        informed_entity: [
          %{route: "28", route_type: 3},
          %{route: "29", route_type: 3}
        ]
      }

      assert Alert.alert_duration(alert, current_time) == 5400
    end
  end
end
