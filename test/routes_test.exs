defmodule RoutesTest do
  use ExUnit.Case, async: true

  alias Api.JsonApi
  alias Api.JsonApi.Item
  alias Routes.Route

  @get_response {:ok,
                 %JsonApi{
                   data: [
                     %Item{
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
                         "text_color" => "FFFFFF",
                         "type" => 3
                       },
                       relationships: %{
                         "line" => [
                           %Item{
                             type: "line",
                             id: "line-SLWaterfront",
                             attributes: nil,
                             relationships: nil
                           }
                         ]
                       }
                     },
                     %Item{
                       type: "route",
                       id: "1",
                       attributes: %{
                         "color" => "FFC72C",
                         "description" => "Key Bus",
                         "direction_destinations" => ["Harvard Square", "Nubian Station"],
                         "direction_names" => ["Outbound", "Inbound"],
                         "fare_class" => "Local Bus",
                         "long_name" => "Harvard Square - Nubian Station",
                         "short_name" => "1",
                         "sort_order" => 50_010,
                         "text_color" => "000000",
                         "type" => 3
                       },
                       relationships: %{
                         "line" => [
                           %Item{
                             type: "line",
                             id: "line-1",
                             attributes: nil,
                             relationships: nil
                           }
                         ]
                       }
                     }
                   ]
                 }}

  describe "all_bus_routes/0" do
    test "returns a list of bus routes" do
      opts = [
        get_fn: fn _, _ -> @get_response end
      ]

      results = Routes.all_bus_routes(opts)

      assert is_list(results)

      Enum.all?(results, &match?(%Route{type: 3}, &1))
    end
  end
end
