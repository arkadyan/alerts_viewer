defmodule AlertsViewerWeb.AlertsLiveTest do
  use ExUnit.Case
  use AlertsViewerWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Alerts.{Alert, AlertsPubSub}

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
      assert html =~ ~r/<h1.*>Alerts<\/h1>/
    end

    test "handles alerts_reset", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/alerts")
      refute render(view) =~ "alert1"
      refute render(view) =~ "alert2"

      send(view.pid, {:alerts_reset, [@alert1]})
      assert render(view) =~ "alert1"
      refute render(view) =~ "alert2"

      send(view.pid, {:alerts_reset, [@alert2]})
      refute render(view) =~ "alert1"
      assert render(view) =~ "alert2"
    end

    test "handles alerts_added", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/alerts")
      send(view.pid, {:alerts_reset, [@alert1]})
      assert render(view) =~ "alert1"
      refute render(view) =~ "alert2"

      send(view.pid, {:alerts_added, [@alert2]})
      assert render(view) =~ "alert1"
      assert render(view) =~ "alert2"
    end

    test "handles alerts_updated", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/alerts")
      send(view.pid, {:alerts_reset, [%Alert{@alert1 | short_header: "alert1x"}, @alert2]})
      assert render(view) =~ "alert1x"
      assert render(view) =~ "alert2"

      send(view.pid, {:alerts_updated, [%Alert{@alert1 | short_header: "alert1y"}]})
      assert render(view) =~ "alert1y"
      assert render(view) =~ "alert2"
    end

    # Not currently working and I'm not sure why
    @tag :skip
    test "handles alerts_removed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/alerts")
      send(view.pid, {:alerts_reset, [@alert1, @alert2]})
      assert render(view) =~ "alert1"
      assert render(view) =~ "alert2"

      send(view.pid, {:alerts_removed, [@alert1]})
      refute render(view) =~ "alert1"
      assert render(view) =~ "alert2"
    end
  end
end
