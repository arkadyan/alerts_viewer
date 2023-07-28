defmodule TripUpdates.TripUpdatesTest do
  use ExUnit.Case

  alias TripUpdates.{StopTimeUpdate, TripUpdate, TripUpdates}

  @trip %{
    trip_id: "t1",
    route_id: "2"
  }

  @stop_time_update_with_waiver %StopTimeUpdate{
    arrival_time: DateTime.new!(~D[2023-07-21], ~T[09:26:08.003], "America/New_York"),
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
    arrival_time: DateTime.new!(~D[2023-07-21], ~T[09:26:08.003], "America/New_York"),
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
      trip: @trip
    },
    %TripUpdate{
      start_date: nil,
      start_time: nil,
      stop_time_update: [
        @stop_time_update_with_waiver,
        @stop_time_update_without_waiver
      ],
      trip: @trip
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
