defmodule Routes.SupervisorTest do
  use ExUnit.Case, async: true

  alias Routes.Supervisor

  describe "start_link/1" do
    test "can start the application" do
      assert {:ok, _pid} = Supervisor.start_link([])
    end
  end

  describe "init/1" do
    test "sets up the registry and pub-sub server" do
      assert {:ok, {_sup_flags, children}} = Supervisor.init(:ok)

      assert length(children) == 2
    end
  end
end
