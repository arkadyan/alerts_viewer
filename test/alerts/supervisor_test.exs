defmodule Alerts.SupervisorTest do
  use ExUnit.Case, async: true

  import Test.Support.Helpers
  alias Alerts.Supervisor

  setup do
    reassign_env(:alerts_viewer, :api_url, "http://example.com")
    reassign_env(:alerts_viewer, :api_key, "12345678")
  end

  describe "init/1" do
    test "definites child_specs" do
      assert {:ok, {_flags, [_child_spec | _]}} = Supervisor.init(:ok)
    end
  end
end
