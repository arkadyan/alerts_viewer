defmodule AlertsViewerWeb.BusControllerTest do
  use AlertsViewerWeb.ConnCase

  import Test.Support.Helpers

  alias Alerts.AlertsPubSub
  alias Plug.Conn
  alias Routes.RouteStatsPubSub

  describe "GET /bus/snapshot/:algorithm" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})
      subscribe_fn = fn _, _ -> :ok end
      {:ok, _pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)
      start_supervised({Registry, keys: :duplicate, name: :route_stats_subscriptions_registry})
      {:ok, _pid} = RouteStatsPubSub.start_link()

      bypass = Bypass.open()
      reassign_env(:alerts_viewer, :api_url, "http://localhost:#{bypass.port}")

      {:ok, %{bypass: bypass}}
    end

    test "downloads a CSV file", %{conn: conn, bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Conn.send_resp(conn, 200, ~s({"data": []}))
      end)

      conn =
        get(
          conn,
          ~p"/bus/snapshot/Elixir.AlertsViewer.DelayAlertAlgorithm.MedianAdherenceComponent"
        )

      assert res = response(conn, 200)

      [header_line | data_lines] = String.split(res, "\n")

      assert header_line =~ ~r/Accuracy,Recall,Precision.*/

      data_lines_with_data = Enum.reject(data_lines, &(&1 == ""))

      for data_line <- data_lines_with_data do
        assert data_line =~ ~r/\d+,\d+,\d+.*/
      end
    end
  end
end
