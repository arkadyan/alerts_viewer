defmodule Api.StreamTest do
  use ExUnit.Case, async: true

  import Test.Support.Helpers
  alias Api.{Event, Stream}
  alias Plug.Conn

  describe "start_link/1" do
    setup do
      reassign_env(:alerts_viewer, :api_url, "http://example.com")
      reassign_env(:alerts_viewer, :api_key, "12345678")

      bypass = Bypass.open()

      {:ok, %{bypass: bypass}}
    end

    test "starts a genserver that sends events", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        conn = Conn.send_chunked(conn, 200)

        data = %{
          "attributes" => [],
          "type" => "vehicle",
          "id" => "vehicle"
        }

        Conn.chunk(conn, "event: reset\ndata: #{Jason.encode!([data])}\n\n")
        conn
      end)

      assert {:ok, sses} =
               [
                 name: :start_link_test,
                 base_url: "http://localhost:#{bypass.port}",
                 path: "/alerts",
                 params: []
               ]
               |> Stream.build_options()
               |> ServerSentEventStage.start_link()

      assert {:ok, pid} = Stream.start_link(name: __MODULE__, subscribe_to: sses)

      assert [%Event{}] =
               [pid]
               |> GenStage.stream()
               |> Enum.take(1)
    end

    test "handles api events", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        conn = Conn.send_chunked(conn, 200)

        data = %{
          "attributes" => [],
          "type" => "vehicle",
          "id" => "vehicle"
        }

        Conn.chunk(conn, "event: reset\ndata: #{Jason.encode!([data])}\n\n")
        Conn.chunk(conn, "event: add\ndata: #{Jason.encode!(data)}\n\n")
        Conn.chunk(conn, "event: update\ndata: #{Jason.encode!(data)}\n\n")
        Conn.chunk(conn, "event: remove\ndata: #{Jason.encode!(data)}\n\n")
        conn
      end)

      assert {:ok, sses} =
               [
                 base_url: "http://localhost:#{bypass.port}",
                 path: "/alerts"
               ]
               |> Stream.build_options()
               |> ServerSentEventStage.start_link()

      assert {:ok, pid} = Stream.start_link(name: __MODULE__, subscribe_to: sses)

      stream = GenStage.stream([pid])

      assert [
               %Event{event: :reset},
               %Event{event: :add},
               %Event{event: :update},
               %Event{event: :remove}
             ] = Enum.take(stream, 4)
    end
  end

  describe "build_options/1" do
    setup do
      reassign_env(:alerts_viewer, :api_url, "http://example.com")
      reassign_env(:alerts_viewer, :api_key, "12345678")
    end

    test "builds the URL and headers including the API key" do
      opts = Stream.build_options(path: "/alerts")

      assert Keyword.get(opts, :url) == "http://example.com/alerts"
      assert Keyword.get(opts, :headers) == [{"x-api-key", "12345678"}]
    end
  end

  describe "init/1" do
    test "defines itself as a `producer_consumer` subscribed to the producer" do
      mock_producer = "MOCK_PRODUCER"
      opts = [subscribe_to: mock_producer]

      assert Stream.init(opts) == {:producer_consumer, %{}, subscribe_to: [mock_producer]}
    end
  end
end
