defmodule SnapshotLogger.SnapshotLoggerTest do
  use ExUnit.Case
  import Test.Support.Helpers
  import ExUnit.CaptureLog
  alias Alerts.{Alert, AlertsPubSub, Store}
  alias Routes.{RouteStats, RouteStatsPubSub}

  alias Api.JsonApi.Item

  @routes [
    %Item{
      type: "route",
      id: "4",
      attributes: %{
        "long_name" => "Logan Airport Terminals - South Station",
        "short_name" => "1",
        "type" => 3
      }
    },
    %Item{
      type: "route",
      id: "1",
      attributes: %{
        "long_name" => "Harvard Square - Nubian Station",
        "short_name" => "4",
        "type" => 3
      }
    },
    %Item{
      type: "route",
      id: "1",
      attributes: %{
        "short_name" => "7",
        "type" => 3
      }
    },
    %Item{
      type: "route",
      id: "1",
      attributes: %{
        "short_name" => "8",
        "type" => 3
      }
    }
  ]

  @alert %Alert{
    id: "112",
    header: "Alert 1",
    effect: :delay,
    created_at: ~U[2023-07-20 10:14:20Z],
    informed_entity: [
      %{activities: [:board, :exit, :ride], route: "1", route_type: 3}
    ]
  }

  @stats_by_route %{
    "1" => %RouteStats{
      id: "111",
      vehicles_schedule_adherence_secs: [10, 20],
      vehicles_instantaneous_headway_secs: [500, 1000],
      vehicles_scheduled_headway_secs: [40, 80],
      vehicles_headway_deviation_secs: [460, 920]
    },
    "4" => %RouteStats{
      id: "113",
      vehicles_schedule_adherence_secs: [30]
    },
    "7" => %RouteStats{
      id: "112",
      vehicles_schedule_adherence_secs: [10, 20],
      vehicles_instantaneous_headway_secs: [500, 1000],
      vehicles_scheduled_headway_secs: [40, 80],
      vehicles_headway_deviation_secs: [460, 920]
    },
    "8" => %RouteStats{
      id: "114",
      vehicles_schedule_adherence_secs: [30]
    }
  }

  describe "snapshot logger" do
    setup do
      subscribe_fn = fn _, _ -> :ok end
      start_supervised({Registry, keys: :duplicate, name: :alerts_subscriptions_registry})
      {:ok, alert_pid} = AlertsPubSub.start_link(subscribe_fn: subscribe_fn)
      start_supervised({Registry, keys: :duplicate, name: :route_stats_subscriptions_registry})
      {:ok, routes_pid} = RouteStatsPubSub.start_link()

      :sys.replace_state(alert_pid, fn state ->
        store =
          Store.init()
          |> Store.add([@alert])

        Map.put(state, :store, store)
      end)

      :sys.replace_state(routes_pid, fn state ->
        Map.put(state, :stats_by_route, @stats_by_route)
      end)

      mock_route_opts = [get_fn: fn _, _ -> {:ok, %{data: @routes}} end]

      {:ok, pid} =
        SnapshotLogger.SnapshotLogger.start_link(
          name: :subscribe,
          subscribe_fn: subscribe_fn,
          route_opts: mock_route_opts
        )

      {:ok, pid: pid}
    end

    test "it logs snapshots", %{pid: pid} do
      set_log_level(:info)

      fun = fn ->
        send(pid, :log)
        pid |> :sys.get_state()
      end

      assert capture_log([format: "$message"], fun) =~
               "{\"max_adherence\":[{\"balanced_accuracy\":50,\"f_measure\":86,\"precision\":75,\"recall\":100,\"value\":0},"
    end
  end
end
