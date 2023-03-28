defmodule Vehicles.SupervisorTest do
  use ExUnit.Case, async: true

  alias Vehicles.Supervisor

  @opts [
    swiftly_realtime_vehicles_url: "http://example.com/swiftly_realtime_vehicles.json",
    swiftly_authorization_key: "12345"
  ]

  describe "start_link/1" do
    test "can start the application" do
      assert {:ok, _pid} = Supervisor.start_link(@opts)
    end
  end

  describe "init/1" do
    test "sets up the data source and consumer" do
      assert {:ok, {_sup_flags, children}} = Supervisor.init(@opts)

      assert length(children) == 2
    end
  end
end
