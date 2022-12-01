defmodule Alerts.StoreTest do
  use ExUnit.Case, async: true

  alias Alerts.{Alert, Store}

  @alert1 %Alert{id: "1", header: "1"}
  @alert2 %Alert{id: "2", header: "2"}
  @alert3 %Alert{id: "3", header: "3"}

  describe "init/0" do
    test "returns a new Store struct" do
      assert %Store{ets: ets} = Store.init()
      assert is_reference(ets)
    end
  end

  describe "all/1" do
    setup do
      ets = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

      :ets.insert(ets, {"1", @alert1})
      :ets.insert(ets, {"2", @alert2})
      :ets.insert(ets, {"3", @alert3})

      {:ok, %{store: %Store{ets: ets}}}
    end

    test "returns all alerts", %{store: store} do
      assert [
               %Alert{id: "1"},
               %Alert{id: "2"},
               %Alert{id: "3"}
             ] = store |> Store.all() |> sorted_by_id()
    end
  end

  describe "by_id/2" do
    setup do
      ets = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

      :ets.insert(ets, {"1", @alert1})
      :ets.insert(ets, {"2", @alert2})
      :ets.insert(ets, {"3", @alert3})

      {:ok, %{store: %Store{ets: ets}}}
    end

    test "returns the alert for the given alert ID", %{store: store} do
      assert {:ok, %Alert{id: "1"}} = Store.by_id(store, "1")
    end

    test "returns :not_found if no alert is found for the given alert ID", %{store: store} do
      assert Store.by_id(store, "missing") == :not_found
    end
  end

  describe "reset/2" do
    setup do
      ets = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

      :ets.insert(ets, {"1", @alert1})

      {:ok, %{store: %Store{ets: ets}}}
    end

    test "deletes all existing data and stores the given alerts", %{store: store} do
      assert %Store{ets: ets} = Store.reset(store, [@alert2, @alert3])
      refute :ets.member(ets, "1")
      assert %Alert{id: "2"} = :ets.lookup_element(ets, "2", 2)
      assert %Alert{id: "3"} = :ets.lookup_element(ets, "3", 2)
    end
  end

  describe "add/2" do
    setup do
      ets = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

      :ets.insert(ets, {"1", @alert1})

      {:ok, %{store: %Store{ets: ets}}}
    end

    test "adds the alerts to the store", %{store: store} do
      assert %Store{ets: ets} = Store.add(store, [@alert2])
      assert :ets.member(ets, "1")
      assert %Alert{id: "2"} = :ets.lookup_element(ets, "2", 2)
    end
  end

  describe "update/2" do
    setup do
      ets = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

      :ets.insert(ets, {"1", @alert1})

      {:ok, %{store: %Store{ets: ets}}}
    end

    test "updates the values of the given alerts in the store", %{store: store} do
      updated_alert = %Alert{
        @alert1
        | header: "updated header"
      }

      assert %Store{ets: ets} = Store.update(store, [updated_alert])
      assert :ets.lookup_element(ets, "1", 2) == updated_alert
    end
  end

  describe "remove/2" do
    setup do
      ets = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

      :ets.insert(ets, {"1", @alert1})
      :ets.insert(ets, {"2", @alert2})

      {:ok, %{store: %Store{ets: ets}}}
    end

    test "removes the alerts with the given IDs from the store", %{store: store} do
      assert %Store{ets: ets} = Store.remove(store, ["1"])

      refute :ets.member(ets, "1")
      assert :ets.member(ets, "2")
    end
  end

  defp sorted_by_id(list), do: Enum.sort_by(list, & &1.id)
end
