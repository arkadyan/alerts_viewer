defmodule AlertsViewerWeb.BusLiveTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use AlertsViewerWeb.ConnCase

  import Phoenix.LiveViewTest
  import Test.Support.Helpers

  alias Alerts.{Alert, AlertsPubSub, Store}
  alias Routes.{RouteStats, RouteStatsPubSub}
  alias TripUpdates.TripUpdatesPubSub

  @alert %Alert{
    id: "1",
    header: "Alert 1",
    effect: :delay,
    created_at: ~U[2023-07-20 10:14:20Z],
    informed_entity: [
      %{activities: [:board, :exit, :ride], route: "1", route_type: 3}
    ]
  }

  @stats_by_route %{
    "1" => %RouteStats{
      id: "1",
      vehicles_schedule_adherence_secs: [100, 200],
      vehicles_instantaneous_headway_secs: [500, 1000],
      vehicles_scheduled_headway_secs: [40, 80],
      vehicles_headway_deviation_secs: [460, 920]
    },
    "4" => %RouteStats{
      id: "4",
      vehicles_schedule_adherence_secs: [30]
    },
    "7" => %RouteStats{
      id: "7",
      vehicles_schedule_adherence_secs: [100, 200],
      vehicles_instantaneous_headway_secs: [500, 1000],
      vehicles_scheduled_headway_secs: [40, 80],
      vehicles_headway_deviation_secs: [460, 920]
    },
    "8" => %RouteStats{
      id: "8",
      vehicles_schedule_adherence_secs: [30]
    }
  }

  @block_waivered_routes ["8"]

  describe "bus live page" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})
      subscribe_fn = fn _, _ -> :ok end
      {:ok, alert_pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)
      start_supervised({Registry, keys: :duplicate, name: :route_stats_subscriptions_registry})
      {:ok, routes_pid} = RouteStatsPubSub.start_link()
      start_supervised({Registry, keys: :duplicate, name: :trip_updates_subscriptions_registry})
      {:ok, update_pid} = TripUpdatesPubSub.start_link()

      :sys.replace_state(alert_pid, fn state ->
        store =
          Store.init()
          |> Store.add([@alert])

        Map.put(state, :store, store)
      end)

      :sys.replace_state(routes_pid, fn state ->
        Map.put(state, :stats_by_route, @stats_by_route)
      end)

      :sys.replace_state(update_pid, fn state ->
        Map.put(state, :block_waivered_routes, @block_waivered_routes)
      end)

      reassign_env(:alerts_viewer, :api_url, "http://localhost:#{54_292}")

      {:ok, %{}}
    end

    test "connected mount", %{conn: conn} do
      use_cassette "routes", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, _view, html} = live(conn, "/bus")
        assert html =~ ~r/Bus Routes/
        assert html =~ ~r/Cool Bus Route/
      end
    end
  end

  describe "bus live components" do
    test "display_minute component renders correctly given assigns", %{conn: _conn} do
      assigns = %{
        route: %Routes.Route{
          id: "1",
          type: 3,
          short_name: "Cool Bus Route",
          long_name: "Cool Bus Route"
        },
        stats_by_route: @stats_by_route,
        stats_function: &RouteStats.vehicles_schedule_adherence_secs/2
      }

      assert render_component(&AlertsViewerWeb.BusLive.display_minutes/1, assigns) ==
               ~s(
  <span class="after:content-[&#39;,&#39;] last:after:content-[&#39;&#39;] ">
    3
  </span>

  <span class="after:content-[&#39;,&#39;] last:after:content-[&#39;&#39;] ">
    2
  </span>
)
    end

    test "result shows true result correctly" do
      route = %Routes.Route{
        id: "1",
        type: 3,
        short_name: "Cool Bus Route",
        long_name: "Cool Bus Route"
      }

      routes_with_current_alerts = [route]
      routes_with_recommended_alerts = [route]

      assigns = %{
        prediction: Enum.member?(routes_with_recommended_alerts, route),
        target: Enum.member?(routes_with_current_alerts, route)
      }

      assert render_component(&AlertsViewerWeb.BusLive.result/1, assigns) ==
               ~s(<div class="text-green-700">
  TP
</div>)
    end

    test "result shows false result correctly" do
      route = %Routes.Route{
        id: "1",
        type: 3,
        short_name: "Cool Bus Route",
        long_name: "Cool Bus Route"
      }

      routes_with_current_alerts = [route]
      routes_with_recommended_alerts = []

      assigns = %{
        prediction: Enum.member?(routes_with_recommended_alerts, route),
        target: Enum.member?(routes_with_current_alerts, route)
      }

      assert render_component(&AlertsViewerWeb.BusLive.result/1, assigns) ==
               ~s(<div class="text-red-700">
  FN
</div>)
    end
  end
end
