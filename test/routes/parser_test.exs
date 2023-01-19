defmodule Routes.ParserTest do
  use ExUnit.Case, async: true

  alias Api.JsonApi.Item
  alias Routes.{Parser, Route}

  describe "parse_route/1" do
    test "parses a JsonApi Item into a Route" do
      item = %Item{
        type: "route",
        id: "741",
        attributes: %{
          "color" => "7C878E",
          "description" => "Key Bus",
          "direction_destinations" => ["Logan Airport Terminals", "South Station"],
          "direction_names" => ["Outbound", "Inbound"],
          "fare_class" => "Rapid Transit",
          "long_name" => "Logan Airport Terminals - South Station",
          "short_name" => "SL1",
          "sort_order" => 10_051,
          "type" => 3
        }
      }

      expected = %Route{
        id: "741",
        type: 3,
        short_name: "SL1",
        long_name: "Logan Airport Terminals - South Station",
        color: "7C878E",
        sort_order: 10_051,
        direction_names: ["Outbound", "Inbound"],
        direction_destinations: ["Logan Airport Terminals", "South Station"]
      }

      assert Parser.parse_route(item) == expected
    end
  end
end
