defmodule TripUpdates.TripUpdatesTest do
  use ExUnit.Case

  alias TripUpdates.{StopTimeUpdate, Trip, TripUpdate, TripUpdates}

  @trip_with_waiver %Trip{
    trip_id: "t1",
    route_id: "2",
    schedule_relationship: :CANCELED
  }

  @trip_without_waiver %Trip{
    trip_id: "t1",
    route_id: "3",
    schedule_relationship: :SKIPPED
  }

  @stop_time_update %StopTimeUpdate{
    arrival_time:
      DateTime.new!(~D[2023-07-21], ~T[09:26:08.003], "America/New_York") |> DateTime.to_unix(),
    departure_time: nil,
    cause_id: 12,
    cause_description: nil,
    remark: nil,
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
        @stop_time_update,
        @stop_time_update
      ],
      trip: @trip_with_waiver
    },
    %TripUpdate{
      start_date: nil,
      start_time: nil,
      stop_time_update: [
        @stop_time_update,
        @stop_time_update
      ],
      trip: @trip_without_waiver
    }
  ]

  describe "start_link/1" do
    test "can start" do
      start_supervised!(TripUpdates)
    end
  end

  describe "handle_events/3" do
    setup do
      events = [@all_updates]

      {:ok, events: events}
    end

    test "returns noreply", %{events: events} do
      response = TripUpdates.handle_events(events, nil, %{})

      assert response == {:noreply, [], %{}}
    end

    test "handles missing trips", %{events: events} do
      response = TripUpdates.handle_events(events, nil, %{})

      assert response == {:noreply, [], %{}}
    end

    test "trips with missing data", %{events: events} do
      response = TripUpdates.handle_events(events, nil, %{})

      assert response == {:noreply, [], %{}}
    end
  end

  describe "backend implementation" do
    test "handles reference info calls that come in after a timeout" do
      state = %{}

      response = TripUpdates.handle_info({make_ref(), %{}}, state)

      assert response == {:noreply, [], state}
    end
  end
end
