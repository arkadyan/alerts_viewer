defmodule TripUpdates.TripUpdatesPubSubTest do
  use ExUnit.Case
  alias TripUpdates.{StopTimeUpdate, TripUpdate, TripUpdatesPubSub}

  @stop_time_update_with_waiver %StopTimeUpdate{
    arrival_time: nil,
    departure_time: nil,
    cause_id: 12,
    cause_description: nil,
    remark: nil,
    schedule_relationship: :SKIPPED,
    status: nil,
    stop_id: "s1",
    stop_sequence: nil,
    uncertainty: nil
  }

  @stop_time_update_without_waiver %StopTimeUpdate{
    arrival_time: nil,
    departure_time: nil,
    cause_id: nil,
    cause_description: nil,
    remark: nil,
    schedule_relationship: :SKIPPED,
    status: nil,
    stop_id: "s1",
    stop_sequence: nil,
    uncertainty: nil
  }

  @all_updates [
    %TripUpdate{
      start_date: nil,
      start_time: nil,
      stop_time_update: [
        @stop_time_update_with_waiver,
        @stop_time_update_with_waiver
      ],
      trip: %{
        trip_id: "t1",
        route_id: "2"
      }
    },
    %TripUpdate{
      start_date: nil,
      start_time: nil,
      stop_time_update: [
        @stop_time_update_with_waiver,
        @stop_time_update_without_waiver
      ],
      trip: %{
        trip_id: "t1",
        route_id: "3"
      }
    }
  ]

  @block_waivered_routes ["2"]

  describe "start_link/1" do
    test "starts the server" do
      assert {:ok, _pid} = TripUpdatesPubSub.start_link(name: :start_link)
    end
  end

  describe "subscribe/1" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :trip_updates_subscriptions_registry})
      {:ok, pid} = TripUpdatesPubSub.start_link(name: :subscribe)
      {:ok, pid: pid}
    end

    test "clients get existing route stats upon subscribing", %{pid: pid} do
      :sys.replace_state(pid, fn state ->
        Map.put(state, :block_waivered_routes, @block_waivered_routes)
      end)

      assert TripUpdatesPubSub.subscribe(pid) == @block_waivered_routes
    end
  end

  describe "all" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :trip_updates_subscriptions_registry})
      {:ok, pid} = TripUpdatesPubSub.start_link(name: :all)

      :sys.replace_state(pid, fn state ->
        Map.put(state, :block_waivered_routes, @block_waivered_routes)
      end)

      {:ok, pid: pid}
    end

    test "gets the blocked routes without subscribing to updates", %{pid: pid} do
      assert TripUpdatesPubSub.all(pid) == @block_waivered_routes
    end
  end

  describe "update_block_waivered_routes" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :trip_updates_subscriptions_registry})
      {:ok, pid} = TripUpdatesPubSub.start_link(name: :update_block_waivered_routes)
      {:ok, pid: pid}
    end

    test "updates list of blocked routes", %{pid: pid} do
      assert :sys.get_state(pid) == %TripUpdatesPubSub{block_waivered_routes: []}

      TripUpdatesPubSub.update_block_waivered_routes(@all_updates, pid)

      assert :sys.get_state(pid) == %TripUpdatesPubSub{
               block_waivered_routes: @block_waivered_routes
             }
    end

    test "broadcasts blocked routes to subscribers", %{pid: pid} do
      TripUpdatesPubSub.subscribe(pid)

      TripUpdatesPubSub.update_block_waivered_routes(@all_updates, pid)

      assert_receive {:block_waivered_routes, @block_waivered_routes}
    end
  end
end
