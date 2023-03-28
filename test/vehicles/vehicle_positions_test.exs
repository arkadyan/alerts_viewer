defmodule Vehicles.VehiclePositionsTest do
  use ExUnit.Case, async: true

  alias Vehicles.VehiclePositions

  describe "start_link/1" do
    test "can start the application" do
      assert {:ok, _pid} = VehiclePositions.start_link([])
    end
  end
end
