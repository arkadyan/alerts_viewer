defmodule TripUpdates.Parser.GTFSRealtimeEnhanced do
  @moduledoc """
  Parser for GTFS-RT enhanced JSON files.
  """

  require Logger
  alias TripUpdates.{StopTimeUpdate, Trip, TripUpdate}

  def parse(binary) when is_binary(binary) do
    binary
    |> Jason.decode!(strings: :copy)
    |> decode_entities()
  end

  @spec decode_entities(map()) :: [TripUpdate.t() | StopTimeUpdate.t()]
  defp decode_entities(%{"entity" => entities}),
    do: Enum.flat_map(entities, &decode_feed_entity(&1))

  defp decode_feed_entity(%{"trip_update" => %{} = trip_update}),
    do: decode_trip_update(trip_update)

  defp decode_feed_entity(_), do: []

  @spec decode_trip_update(map) :: [TripUpdate.t()]
  def decode_trip_update(trip_update) do
    trip = decode_trip(Map.get(trip_update, "trip"))

    stop_time_updates =
      Map.get(trip_update, "stop_time_update") |> Enum.map(&decode_stop_update(&1))

    [
      TripUpdate.new(
        stop_time_update: stop_time_updates,
        timestamp: Map.get(trip_update, "timestamp"),
        trip: trip
      )
    ]
  end

  defp decode_stop_update(stu) do
    {arrival_time, arrival_uncertainty} = time_from_event(Map.get(stu, "arrival"))
    {departure_time, departure_uncertainty} = time_from_event(Map.get(stu, "departure"))

    StopTimeUpdate.new(
      stop_id: Map.get(stu, "stop_id"),
      stop_sequence: Map.get(stu, "stop_sequence"),
      schedule_relationship: schedule_relationship(Map.get(stu, "schedule_relationship")),
      arrival_time: arrival_time,
      departure_time: departure_time,
      uncertainty: arrival_uncertainty || departure_uncertainty,
      status: Map.get(stu, "boarding_status"),
      cause_id: Map.get(stu, "cause_id"),
      cause_description: Map.get(stu, "cause_description"),
      remark: Map.get(stu, "remark")
    )
  end

  @spec decode_trip(nil | map) :: nil | Trip.t()
  defp decode_trip(nil), do: nil

  defp decode_trip(trip) do
    Trip.new(
      trip_id: Map.get(trip, "trip_id"),
      route_id: Map.get(trip, "route_id"),
      direction_id: Map.get(trip, "direction_id"),
      start_date: date(Map.get(trip, "start_date")),
      start_time: Map.get(trip, "start_time"),
      schedule_relationship: schedule_relationship(Map.get(trip, "schedule_relationship"))
    )
  end

  @spec date(String.t() | nil) :: :calendar.date() | nil
  def date(nil) do
    nil
  end

  def date(<<year_str::binary-4, month_str::binary-2, day_str::binary-2>>) do
    {
      String.to_integer(year_str),
      String.to_integer(month_str),
      String.to_integer(day_str)
    }
  end

  def date(date) when is_binary(date) do
    {:ok, date} = Date.from_iso8601(date)
    Date.to_erl(date)
  end

  defp time_from_event(nil), do: {nil, nil}
  defp time_from_event(%{"time" => time} = map), do: {time, Map.get(map, "uncertainty", nil)}

  @spec schedule_relationship(String.t() | nil) :: atom()
  defp schedule_relationship(nil), do: :SCHEDULED

  for relationship <- ~w(SCHEDULED ADDED UNSCHEDULED CANCELED SKIPPED NO_DATA)a do
    defp schedule_relationship(unquote(Atom.to_string(relationship))), do: unquote(relationship)
  end

  @spec current_status(String.t() | nil) :: atom()
  # default
  defp current_status(nil), do: :IN_TRANSIT_TO

  for status <- ~w(INCOMING_AT STOPPED_AT IN_TRANSIT_TO)a do
    defp current_status(unquote(Atom.to_string(status))), do: unquote(status)
  end
end
