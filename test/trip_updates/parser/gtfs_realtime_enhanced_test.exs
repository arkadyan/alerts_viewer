defmodule TripUpdates.Parser.GTFSRealtimeEnhancedTest do
  use ExUnit.Case, async: true

  import Test.Support.Helpers

  alias TripUpdates.Parser.GTFSRealtimeEnhanced
  alias TripUpdates.{StopTimeUpdate, TripUpdate}

  describe "parse/1" do
    test "parsing an enhanced TripUpdates JSON file returns TripUpdate and StopTimeUpdate structs" do
      binary = File.read!(fixture_path("trip_updates_enhanced.json"))
      parsed = GTFSRealtimeEnhanced.parse(binary)
      assert is_list(parsed)
      assert Enum.all?(parsed, &(&1.__struct__ in [TripUpdate]))
    end

    test "parsing a TripUpdates file preserves the remark field on StopTimeUpdate structs" do
      binary = File.read!(fixture_path("trip_updates_enhanced.json"))

      stop_time_updates = hd(GTFSRealtimeEnhanced.parse(binary)).stop_time_update

      assert length(stop_time_updates) > 0
      assert Enum.all?(stop_time_updates, &(&1.__struct__ in [StopTimeUpdate]))
      assert Enum.all?(stop_time_updates, &match?(%{remark: _remark}, &1))
    end
  end

  describe "date/1" do
    test "parses an epoch string" do
      assert GTFSRealtimeEnhanced.date("20190517") == {2019, 5, 17}
    end

    test "parses an ISO 8601:2004 string" do
      assert GTFSRealtimeEnhanced.date("2015-01-23") == {2015, 1, 23}
    end

    test "returns nil when passed nil" do
      assert GTFSRealtimeEnhanced.date(nil) == nil
    end
  end
end
