defmodule AlertsViewerWeb.AlertsLiveTest do
  use ExUnit.Case
  use AlertsViewerWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Alerts.{Alert, AlertsPubSub}

  doctest AlertsViewerWeb.AlertsLive

  @alert1 %Alert{
    id: "alert1",
    short_header: "alert1",
    informed_entity: [],
    active_period: [{nil, nil}]
  }
  @alert2 %Alert{
    id: "alert2",
    short_header: "alert2",
    informed_entity: [],
    active_period: [{nil, nil}]
  }

  describe "alerts list page" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})
      subscribe_fn = fn _, _ -> :ok end
      {:ok, _pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)
      :ok
    end

    test "connected mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/alerts")
      assert html =~ ~r/Alerts/
    end

    test "handles alerts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/alerts")
      refute render(view) =~ "alert1"
      refute render(view) =~ "alert2"

      send(view.pid, {:alerts, [@alert1]})
      assert render(view) =~ "alert1"
      refute render(view) =~ "alert2"

      send(view.pid, {:alerts, [@alert2]})
      refute render(view) =~ "alert1"
      assert render(view) =~ "alert2"
    end
  end
end
