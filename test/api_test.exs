defmodule ApiTest do
  use ExUnit.Case, async: true

  alias Api.JsonApi
  alias HTTPoison.{Error, Response}
  alias Plug.Conn

  setup _ do
    bypass = Bypass.open()

    opts = [
      base_url: "http://localhost:#{bypass.port}",
      api_key: ""
    ]

    {:ok, %{bypass: bypass, opts: opts}}
  end

  describe "get" do
    test "normal responses return a JsonApi struct", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, fn conn ->
        assert conn.request_path == "/normal_response"
        Conn.send_resp(conn, 200, ~s({"data": []}))
      end)

      {:ok, response} = Api.get("/normal_response", [], opts)
      assert %JsonApi{} = response
      refute response.data == %{}
    end

    test "missing endpoints return an error", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, fn conn ->
        assert conn.request_path == "/missing"
        Conn.send_resp(conn, 404, ~s({"errors":[{"code": "not_found"}]}))
      end)

      response = Api.get("/missing", [], opts)
      assert {:error, [%JsonApi.Error{code: "not_found"}]} = response
    end

    test "can't connect returns an error", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)

      response = Api.get("/cant_connect", [], opts)
      assert {:error, %{reason: _}} = response
    end
  end

  describe "body/1" do
    test "returns a normal body if there's no content-encoding" do
      response = %Response{headers: [], body: "body"}
      assert Api.body(response) == {:ok, "body"}
    end

    test "decodes a gzip encoded body" do
      body = "body"
      encoded_body = :zlib.gzip(body)
      header = {"Content-Encoding", "gzip"}
      response = %Response{headers: [header], body: encoded_body}
      assert {:ok, ^body} = Api.body(response)
    end

    test "returns an error if the gzip body is invalid" do
      encoded_body = "bad gzip"
      header = {"Content-Encoding", "gzip"}
      response = %Response{headers: [header], body: encoded_body}
      assert {:error, :data_error} = Api.body(response)
    end

    test "returns an error if we have an error instead of a response" do
      error = %Error{}
      assert ^error = Api.body(error)
    end
  end
end
