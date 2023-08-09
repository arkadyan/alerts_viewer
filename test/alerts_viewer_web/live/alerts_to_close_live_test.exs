defmodule AlertsViewerWeb.AlertsToCloseLiveTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use AlertsViewerWeb.ConnCase

  import Phoenix.LiveViewTest
  import Test.Support.Helpers

  alias Alerts.{Alert, AlertsPubSub, Store}
  alias Routes.{RouteStats, RouteStatsPubSub}
  alias TripUpdates.TripUpdatesPubSub

  @alerts [
    %Alert{
      id: "1",
      header: "Alert 1",
      effect: :delay,
      created_at: DateTime.now!("America/New_York") |> DateTime.add(-1, :hour),
      informed_entity: [
        %{activities: [:board, :exit, :ride], route: "1", route_type: 3}
      ]
    },
    %Alert{
      id: "4",
      header: "Alert 2",
      effect: :delay,
      created_at: DateTime.now!("America/New_York") |> DateTime.add(-2, :hour),
      informed_entity: [
        %{activities: [:board, :exit, :ride], route: "4", route_type: 3}
      ]
    }
  ]

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
      vehicles_schedule_adherence_secs: [400, 500],
      vehicles_instantaneous_headway_secs: [1500, 2000],
      vehicles_scheduled_headway_secs: [400, 880],
      vehicles_headway_deviation_secs: [1100, 1120]
    }
  }

  @block_waivered_routes ["4"]

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
          |> Store.add(@alerts)

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
        {:ok, _view, html} = live(conn, "/alerts-to-close")
        assert html =~ ~r/Alerts/
        assert html =~ ~r/Cool Bus Route/
        assert html =~ ~r/Cooler Bus Route/
      end
    end
  end
end
