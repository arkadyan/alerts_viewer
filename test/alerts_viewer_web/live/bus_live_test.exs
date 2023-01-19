defmodule AlertsViewerWeb.BusLiveTest do
  use ExUnit.Case
  use AlertsViewerWeb.ConnCase

  import Phoenix.LiveViewTest
  import Test.Support.Helpers

  alias Alerts.AlertsPubSub
  alias Plug.Conn

  describe "bus live page" do
    setup do
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})
      subscribe_fn = fn _, _ -> :ok end
      {:ok, _pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)

      bypass = Bypass.open()
      reassign_env(:alerts_viewer, :api_url, "http://localhost:#{bypass.port}")

      {:ok, %{bypass: bypass}}
    end

    test "connected mount", %{conn: conn, bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Conn.send_resp(conn, 200, ~s({"data": []}))
      end)

      {:ok, _view, html} = live(conn, "/bus")

      assert html =~ ~r/Bus Routes/
    end
  end
end
