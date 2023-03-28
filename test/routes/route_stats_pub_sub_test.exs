defmodule Routes.RouteStatsPubSubTest do
  use ExUnit.Case

  alias Routes.{RouteStats, RouteStatsPubSub}
  alias Vehicles.Vehicle

  @vehicles_by_route %{
    "39" => [
      %Vehicle{schedule_adherence_secs: 10},
      %Vehicle{schedule_adherence_secs: 20}
    ],
    "66" => [
      %Vehicle{schedule_adherence_secs: 30}
    ]
  }

  @stats_by_route %{
    "39" => %RouteStats{
      id: "39",
      vehicles_schedule_adherence_secs: [20, 10]
    },
    "66" => %RouteStats{
      id: "66",
      vehicles_schedule_adherence_secs: [30]
    }
  }

  describe "start_link/1" do
    test "starts the server" do
      assert {:ok, _pid} = RouteStatsPubSub.start_link(name: :start_link)
    end
  end

  describe "subscribe/1" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :route_stats_subscriptions_registry})
      {:ok, pid} = RouteStatsPubSub.start_link(name: :subscribe)
      {:ok, pid: pid}
    end

    test "clients get existing route stats upon subscribing", %{pid: pid} do
      :sys.replace_state(pid, fn state ->
        Map.put(state, :stats_by_route, @stats_by_route)
      end)

      assert RouteStatsPubSub.subscribe(pid) == @stats_by_route
    end
  end

  describe "update_stats" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :route_stats_subscriptions_registry})
      {:ok, pid} = RouteStatsPubSub.start_link(name: :update_vehicles)
      {:ok, pid: pid}
    end

    test "updates stats for each route from vehicle data", %{pid: pid} do
      assert :sys.get_state(pid) == %RouteStatsPubSub{stats_by_route: %{}}

      RouteStatsPubSub.update_stats(@vehicles_by_route, pid)

      assert :sys.get_state(pid) == %RouteStatsPubSub{stats_by_route: @stats_by_route}
    end

    test "broadcasts new route stats to subscribers", %{pid: pid} do
      RouteStatsPubSub.subscribe(pid)

      RouteStatsPubSub.update_stats(@vehicles_by_route, pid)

      assert_receive {:stats_by_route, @stats_by_route}
    end
  end
end
