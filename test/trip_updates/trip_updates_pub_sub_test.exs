defmodule TripUpdates.TripUpdatesPubSubTest do
  use ExUnit.Case
  alias TripUpdates.{StopTimeUpdate, TripUpdate, TripUpdatesPubSub}

  @stop_time_update_with_waiver %StopTimeUpdate{
    arrival_time:
      DateTime.now!("America/New_York") |> DateTime.add(2, :hour) |> DateTime.to_unix(),
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
    arrival_time: DateTime.now!("America/New_York") |> DateTime.to_unix(),
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

  describe "is_it_fresh" do
    test "returns true if most recent stop time is in the future" do
      current_time = DateTime.new!(~D[2023-07-21], ~T[09:26:08.003], "America/New_York")

      fresh_stoptime =
        Map.put(
          @stop_time_update_with_waiver,
          :arrival_time,
          DateTime.add(current_time, 1, :hour) |> DateTime.to_unix()
        )

      stale_stoptime =
        Map.put(
          @stop_time_update_with_waiver,
          :arrival_time,
          DateTime.add(current_time, -1, :hour) |> DateTime.to_unix()
        )

      stale_tripupdate = %TripUpdate{
        stop_time_update: [
          stale_stoptime,
          fresh_stoptime
        ],
        trip: %{
          trip_id: "t1",
          route_id: "2"
        }
      }

      assert TripUpdatesPubSub.is_it_fresh?(stale_tripupdate, current_time) == true
    end

    test "returns false if most recent stop time in the past" do
      current_time = DateTime.new!(~D[2023-07-21], ~T[16:26:08.003], "America/New_York")

      stale_stoptime =
        Map.put(
          @stop_time_update_with_waiver,
          :arrival_time,
          DateTime.add(current_time, -2, :hour)
          |> DateTime.to_unix()
        )

      staler_stoptime =
        Map.put(
          @stop_time_update_with_waiver,
          :arrival_time,
          DateTime.add(current_time, -3, :hour)
          |> DateTime.to_unix()
        )

      stale_tripupdate = %TripUpdate{
        stop_time_update: [
          stale_stoptime,
          staler_stoptime
        ],
        trip: %{
          trip_id: "t1",
          route_id: "2"
        }
      }

      assert TripUpdatesPubSub.is_it_fresh?(stale_tripupdate, current_time) == false
    end

    test "returns false if all stop time update arrival times are nil" do
      bad_stoptime =
        Map.put(
          @stop_time_update_with_waiver,
          :arrival_time,
          nil
        )

      bad_tripupdate = %TripUpdate{
        stop_time_update: [
          bad_stoptime,
          bad_stoptime
        ],
        trip: %{
          trip_id: "t1",
          route_id: "2"
        }
      }

      assert TripUpdatesPubSub.is_it_fresh?(bad_tripupdate) == false
    end
  end
end
