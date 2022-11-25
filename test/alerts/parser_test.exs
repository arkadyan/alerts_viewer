defmodule Alerts.ParserTest do
  use ExUnit.Case, async: true

  alias Alerts.{Alert, Parser}
  alias Api.JsonApi.Item

  @alert_json_item %Item{
    type: "alert",
    id: "12345",
    attributes: %{
      "active_period" => [
        %{
          "end" => "2022-11-22T14:07:38-05:00",
          "start" => "2022-11-22T11:17:05-05:00"
        }
      ],
      "banner" => nil,
      "cause" => "CONSTRUCTION",
      "created_at" => "2022-11-22T11:17:06-05:00",
      "description" =>
        "Affected direction: Outbound\r\n\r\nAffected stops:\r\nSummit St @ Metropolitan Ave\r\nSummit St @ Milton Ave",
      "effect" => "DETOUR",
      "header" =>
        "Route 24 outbound detoured due to construction. Connections can be made at Metropolitan Ave @ Highland St & Milton Ave @ Highland St.",
      "informed_entity" => [
        %{
          "activities" => ["BOARD", "EXIT"],
          "direction_id" => 0,
          "route" => "24",
          "route_type" => 3,
          "stop" => "6397"
        },
        %{
          "activities" => ["BOARD", "EXIT"],
          "direction_id" => 0,
          "route" => "24",
          "route_type" => 3,
          "stop" => "6398"
        }
      ],
      "lifecycle" => "NEW",
      "service_effect" => "Route 24 detour",
      "severity" => 7,
      "short_header" =>
        "Route 24 outbound detoured due to construction. Connections can be made at Metropolitan Ave @ Highland St & Milton Ave @ Highland St.",
      "timeframe" => "ongoing",
      "updated_at" => "2022-11-22T11:17:06-05:00",
      "url" => "https://mbta.com/test-example"
    },
    relationships: %{}
  }

  describe "parse/1" do
    test "converts API Json data into an Alert struct" do
      assert Parser.parse(@alert_json_item) == %Alert{
               id: "12345",
               active_period: [
                 {shift_five_hours(~D[2022-11-22], ~T[11:17:05]),
                  shift_five_hours(~D[2022-11-22], ~T[14:07:38])}
               ],
               banner: nil,
               cause: :construction,
               created_at: shift_five_hours(~D[2022-11-22], ~T[11:17:06]),
               description:
                 "Affected direction: Outbound\r\n\r\nAffected stops:\r\nSummit St @ Metropolitan Ave\r\nSummit St @ Milton Ave",
               effect: :detour,
               header:
                 "Route 24 outbound detoured due to construction. Connections can be made at Metropolitan Ave @ Highland St & Milton Ave @ Highland St.",
               informed_entity: [
                 %{
                   activities: [:board, :exit],
                   direction_id: 0,
                   route: "24",
                   route_type: 3,
                   stop: "6397"
                 },
                 %{
                   activities: [:board, :exit],
                   direction_id: 0,
                   route: "24",
                   route_type: 3,
                   stop: "6398"
                 }
               ],
               lifecycle: :new,
               service_effect: "Route 24 detour",
               severity: 7,
               short_header:
                 "Route 24 outbound detoured due to construction. Connections can be made at Metropolitan Ave @ Highland St & Milton Ave @ Highland St.",
               timeframe: "ongoing",
               updated_at: shift_five_hours(~D[2022-11-22], ~T[11:17:06]),
               url: "https://mbta.com/test-example"
             }
    end
  end

  defp shift_five_hours(date, time) do
    date
    |> DateTime.new!(time, "Etc/UTC")
    |> DateTime.add(5, :hour)
  end
end
