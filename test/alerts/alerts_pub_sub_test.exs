defmodule Alerts.AlertsPubSubTest do
  use ExUnit.Case, async: true

  alias Alerts.{Alert, AlertsPubSub, Store}

  @alert %Alert{id: "1", header: "Alert 1"}

  describe "start_link/1" do
    test "starts the server" do
      subscribe_fn = fn _, _ -> :ok end

      assert {:ok, _pid} = AlertsPubSub.start_link(name: :start_link, subscribe_fn: subscribe_fn)
    end
  end

  describe "subscribe/1" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(name: :subscribe, subscribe_fn: subscribe_fn)

      {:ok, pid: pid}
    end

    test "clients get existing alerts upon subscribing", %{pid: pid} do
      :sys.replace_state(pid, fn state ->
        store =
          Store.init()
          |> Store.add([@alert])

        Map.put(state, :store, store)
      end)

      assert AlertsPubSub.subscribe(pid) == [@alert]
    end
  end

  describe "all/1" do
    setup do
      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(name: :subscribe, subscribe_fn: subscribe_fn)

      {:ok, pid: pid}
    end

    test "returns all stored alerts", %{pid: pid} do
      :sys.replace_state(pid, fn state ->
        store =
          Store.init()
          |> Store.add([@alert])

        Map.put(state, :store, store)
      end)

      assert AlertsPubSub.all(pid) == [@alert]
    end
  end

  describe "get/2" do
    setup do
      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(name: :subscribe, subscribe_fn: subscribe_fn)

      {:ok, pid: pid}
    end

    test "returns the requested alert", %{pid: pid} do
      :sys.replace_state(pid, fn state ->
        store =
          Store.init()
          |> Store.add([@alert])

        Map.put(state, :store, store)
      end)

      assert AlertsPubSub.get("1", pid) == {:ok, @alert}
    end

    test "returns :not_found if the requested alert is not in the store", %{pid: pid} do
      assert AlertsPubSub.get("missing", pid) == :not_found
    end
  end

  describe "handle_info/2 - {:reset, alerts}" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(name: :subscribe, subscribe_fn: subscribe_fn)

      {:ok, pid: pid}
    end

    test "resets the alerts", %{pid: pid} do
      send(pid, {:reset, [@alert]})

      assert pid |> :sys.get_state() |> Map.get(:store) |> Store.all() == [@alert]
    end

    test "broadcasts new alerts lists to subscribers", %{pid: pid} do
      AlertsPubSub.subscribe(pid)

      send(pid, {:reset, [@alert]})

      assert_receive {:alerts, [@alert]}
    end
  end

  describe "handle_info/2 - {:add, alerts}" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(name: :subscribe, subscribe_fn: subscribe_fn)

      {:ok, pid: pid}
    end

    test "adds the new alerts", %{pid: pid} do
      send(pid, {:add, [@alert]})

      assert pid |> :sys.get_state() |> Map.get(:store) |> Store.all() == [@alert]
    end

    test "broadcasts new alerts lists to subscribers", %{pid: pid} do
      AlertsPubSub.subscribe(pid)

      send(pid, {:add, [@alert]})

      assert_receive {:alerts, [@alert]}
    end
  end

  describe "handle_info/2 - {:update, alerts}" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(name: :subscribe, subscribe_fn: subscribe_fn)

      :sys.replace_state(pid, fn state ->
        Map.put(state, :alerts, [@alert])
      end)

      {:ok, pid: pid}
    end

    test "updates the alerts", %{pid: pid} do
      send(pid, {:update, [@alert]})

      assert pid |> :sys.get_state() |> Map.get(:store) |> Store.all() == [@alert]
    end

    test "broadcasts new alerts lists to subscribers", %{pid: pid} do
      AlertsPubSub.subscribe(pid)

      send(pid, {:update, [@alert]})

      assert_receive {:alerts, [@alert]}
    end
  end

  describe "handle_info/2 - {:remove, alert_ids}" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})

      subscribe_fn = fn _, _ -> :ok end
      {:ok, pid} = AlertsPubSub.start_link(name: :subscribe, subscribe_fn: subscribe_fn)

      :sys.replace_state(pid, fn state ->
        Map.put(state, :alerts, [@alert])
      end)

      {:ok, pid: pid}
    end

    test "removes the given alerts", %{pid: pid} do
      send(pid, {:remove, ["12345"]})

      assert pid |> :sys.get_state() |> Map.get(:store) |> Store.all() == []
    end

    test "broadcasts new predictions lists to subscribers", %{pid: pid} do
      AlertsPubSub.subscribe(pid)

      send(pid, {:remove, ["12345"]})

      assert_receive {:alerts, []}
    end
  end
end
