defmodule Alerts.AlertTest do
  use ExUnit.Case, async: true

  alias Alerts.Alert

  describe "entities_with_icons" do
    test "returns a list of route IDs or facility activities representing the alert's informed entities" do
      alert = %Alert{
        id: "1",
        header: "Alert 1",
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
        header: "Alert 1",
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
        header: "Alert 1",
        informed_entity: [
          %{activities: [:bringing_bike, :store_bike], facility: "772", stop: "70511"}
        ]
      }

      assert Alert.entities_with_icons(alert) == ["bike"]
    end
  end
end
