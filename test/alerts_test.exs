defmodule AlertsTest do
  use ExUnit.Case, async: true

  alias Alerts.{Alert, AlertsPubSub, Store}

  @alert %Alert{id: "1", header: "Alert 1"}

  describe "subscribe/0" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)

      {:ok, pid: pid}
    end

    test "returns a list of alerts" do
      assert [] = Alerts.subscribe()
    end
  end

  describe "all/0" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)

      :sys.replace_state(pid, fn state ->
        store =
          Store.init()
          |> Store.add([@alert])

        Map.put(state, :store, store)
      end)

      {:ok, pid: pid}
    end

    test "returns a list of alerts" do
      assert Alerts.all() == [@alert]
    end
  end

  describe "get/1" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)

      :sys.replace_state(pid, fn state ->
        store =
          Store.init()
          |> Store.add([@alert])

        Map.put(state, :store, store)
      end)

      {:ok, pid: pid}
    end

    test "returns the requested alert" do
      assert Alerts.get("1") == {:ok, @alert}
    end

    test "returns :not_found if the requested alert is not in the store" do
      assert Alerts.get("missing") == :not_found
    end
  end

  describe "by_effect/2" do
    test "filters the list of alerts by effect type" do
      delay_alert = %Alert{effect: :delay}
      detour_alert = %Alert{effect: :detour}

      assert Alerts.by_effect([delay_alert, detour_alert], "detour") == [detour_alert]
    end

    test "returns all alerts when filtering on an empty string" do
      delay_alert = %Alert{effect: :delay}
      detour_alert = %Alert{effect: :detour}

      assert Alerts.by_effect([delay_alert, detour_alert], "") == [delay_alert, detour_alert]
    end
  end

  describe "by_service/2" do
    test "filters the list of alerts by service type" do
      bus_alert = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ]
      }

      subway_alert = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "Orange", route_type: 2}
        ]
      }

      assert Alerts.by_service([bus_alert, subway_alert], "3") == [bus_alert]
    end

    test "filters on access service type" do
      bus_alert = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ]
      }

      using_wheelchair_alert = %Alert{
        informed_entity: [
          %{activities: [:using_wheelchair], facility: "772", stop: "70511"}
        ]
      }

      assert Alerts.by_service([bus_alert, using_wheelchair_alert], "access") == [
               using_wheelchair_alert
             ]
    end

    test "returns all alerts when filtering on an empty string" do
      bus_alert = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "28", route_type: 3}
        ]
      }

      subway_alert = %Alert{
        informed_entity: [
          %{activities: [:board, :exit, :ride], route: "Orange", route_type: 2}
        ]
      }

      assert Alerts.by_service([bus_alert, subway_alert], "") == [bus_alert, subway_alert]
    end
  end

  describe "search/2" do
    test "searches alerts based on the ID field" do
      alert_1 = %Alert{id: "1"}
      alert_2 = %Alert{id: "2"}

      assert Alerts.search([alert_1, alert_2], "2") == [alert_2]
    end

    test "searches alerts based on the header field" do
      foo_alert = %Alert{header: "XXX foo YYY"}
      bar_alert = %Alert{header: "XXX bar YYY"}

      assert Alerts.search([foo_alert, bar_alert], "foo") == [foo_alert]
    end

    test "searches alerts based on the description field" do
      foo_alert = %Alert{description: "XXX foo YYY"}
      bar_alert = %Alert{description: "XXX bar YYY"}

      assert Alerts.search([foo_alert, bar_alert], "foo") == [foo_alert]
    end
  end
end
