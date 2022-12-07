defmodule Alerts.StreamTest do
  use ExUnit.Case, async: true

  alias Alerts.{Alert, Stream}
  alias Api.{Event, JsonApi}
  alias Api.JsonApi.Item

  @alert_json %JsonApi{
    data: [
      %Item{
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
    ]
  }

  setup tags do
    {:ok, mock_api} =
      GenStage.from_enumerable([
        %Event{event: :reset, data: @alert_json}
      ])

    name = :"stream_test_#{tags.line}"

    {:ok, mock_api: mock_api, name: name}
  end

  describe "start_link/1" do
    test "starts a GenServer that publishes alerts", %{mock_api: mock_api, name: name} do
      test_pid = self()

      broadcast_fn = fn Alerts.PubSub, "alerts", {type, data} ->
        send(test_pid, {type, data})
        :ok
      end

      assert {:ok, _} =
               Stream.start_link(
                 name: name,
                 broadcast_fn: broadcast_fn,
                 subscribe_to: mock_api
               )

      assert_receive {:reset, [%Alert{id: "12345"}]}
    end

    test "publishes :remove events as a list of IDs", %{name: name} do
      {:ok, mock_api} =
        GenStage.from_enumerable([
          %Event{event: :remove, data: @alert_json}
        ])

      test_pid = self()

      broadcast_fn = fn Alerts.PubSub, "alerts", {type, data} ->
        send(test_pid, {:received_broadcast, {type, data}})
        :ok
      end

      assert {:ok, _} =
               Stream.start_link(
                 name: name,
                 broadcast_fn: broadcast_fn,
                 subscribe_to: mock_api
               )

      assert_receive {:received_broadcast, {type, data}}
      assert type == :remove
      assert data == ["12345"]
    end
  end
end
