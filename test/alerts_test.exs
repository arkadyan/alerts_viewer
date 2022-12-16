defmodule AlertsTest do
  use ExUnit.Case, async: true

  alias alias Alerts.AlertsPubSub

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

      {:ok, pid: pid}
    end

    test "returns a list of alerts" do
      assert [] = Alerts.all()
    end
  end
end
