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
end
