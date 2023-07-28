defmodule AlertsViewerWeb.AlertsToCloseLiveTest do
  use ExUnit.Case
  use AlertsViewerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Alerts.AlertsPubSub
  alias Routes.RouteStatsPubSub
  alias TripUpdates.TripUpdatesPubSub

  describe "bus live page" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})
      subscribe_fn = fn _, _ -> :ok end
      {:ok, _pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)
      start_supervised({Registry, keys: :duplicate, name: :route_stats_subscriptions_registry})
      {:ok, _pid} = RouteStatsPubSub.start_link()
      start_supervised({Registry, keys: :duplicate, name: :trip_updates_subscriptions_registry})
      {:ok, _pid} = TripUpdatesPubSub.start_link()

      {:ok, %{}}
    end

    test "connected mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/alerts-to-close")

      assert html =~ ~r/Alerts/
    end
  end
end
