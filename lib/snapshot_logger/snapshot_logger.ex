defmodule SnapshotLogger.SnapshotLogger do
  @moduledoc """
  Logs algorithm snapshots on a cadence.
  """
  use GenServer
  require Logger
  alias Alerts.Alert
  alias AlertsViewer.DelayAlertAlgorithm
  alias AlertsViewerWeb.DateTimeHelpers, as: DTH
  alias Routes.{Route, RouteStats, RouteStatsPubSub}
  alias TripUpdates.TripUpdatesPubSub

  @cadence 5 * 60 * 1000

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  @spec init(keyword) ::
          {:ok,
           %{
             block_waivered_routes: list,
             bus_routes: list,
             delay_alert_algorithm_modules: any,
             routes_with_current_alerts: list,
             stats_by_route: map
           }}
  def init(opts) do
    delay_alert_algorithm_modules =
      Application.get_env(:alerts_viewer, :delay_alert_algorithm_components)

    bus_alerts = Alerts.subscribe() |> filtered_by_bus() |> filtered_by_delay_type()
    bus_routes = opts |> Keyword.get(:route_opts, []) |> Routes.all_bus_routes()
    stats_by_route = RouteStatsPubSub.subscribe()
    block_waivered_routes = TripUpdatesPubSub.subscribe()
    routes_with_current_alerts = Enum.filter(bus_routes, &delay_alert?(&1, bus_alerts))
    schedule_logs()

    {:ok,
     %{
       bus_routes: bus_routes,
       stats_by_route: stats_by_route,
       routes_with_current_alerts: routes_with_current_alerts,
       block_waivered_routes: block_waivered_routes,
       delay_alert_algorithm_modules: delay_alert_algorithm_modules
     }}
  end

  @impl GenServer
  def handle_info({:stats_by_route, stats_by_route}, state) do
    {:noreply, Map.put(state, :stats_by_route, stats_by_route)}
  end

  @impl true
  def handle_info({:block_waivered_routes, block_waivered_routes}, state) do
    {:noreply, Map.put(state, :block_waivered_routes, block_waivered_routes)}
  end

  @impl GenServer
  def handle_info({:alerts, alerts}, state) do
    bus_alerts = filtered_by_bus(alerts) |> filtered_by_delay_type()

    routes_with_current_alerts = Enum.filter(state.bus_routes, &delay_alert?(&1, bus_alerts))

    state =
      Map.put(
        state,
        :routes_with_current_alerts,
        routes_with_current_alerts
      )

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:log, state) do
    schedule_logs()

    timestamp = DateTime.now!("America/New_York")

    algorithm_snapshots =
      Enum.map(state.delay_alert_algorithm_modules, fn module ->
        make_algo_snapshot(module, state, timestamp)
      end)

    to_be_logged =
      bus_route_snapshots(state, timestamp) ++
        algorithm_snapshots ++
        [
          best_variable_snapshot(algorithm_snapshots, :f_measure, "best f_measure snapshot"),
          best_variable_snapshot(algorithm_snapshots, :balanced_accuracy, "best bacc snapshot")
        ]

    Enum.each(to_be_logged, &Logger.info(Jason.encode_to_iodata!(&1)))
    {:noreply, state}
  end

  defp bus_route_snapshots(state, timestamp) do
    stats_by_route = state.stats_by_route

    Enum.map(state.bus_routes, fn route ->
      %{
        name: "bus route snapshot",
        route: Route.name(route),
        timestamp: timestamp,
        individual_vehicle_schedule_adherence:
          format_stats(route, stats_by_route, &RouteStats.vehicles_schedule_adherence_secs/2),
        individual_vehicle_instantaneous_headway:
          format_stats(route, stats_by_route, &RouteStats.vehicles_instantaneous_headway_secs/2),
        individual_vehicle_headway_deviation:
          format_stats(route, stats_by_route, &RouteStats.vehicles_headway_deviation_secs/2),
        max_schedule_adherence:
          RouteStats.max_schedule_adherence(stats_by_route, route) |> DTH.seconds_to_minutes(),
        median_schedule_adherence:
          RouteStats.median_schedule_adherence(stats_by_route, route) |> DTH.seconds_to_minutes(),
        standard_deviation_of_schedule_adherence:
          RouteStats.standard_deviation_of_schedule_adherence(stats_by_route, route)
          |> DTH.seconds_to_minutes(),
        median_instantaneous_headway:
          RouteStats.median_instantaneous_headway(stats_by_route, route)
          |> DTH.seconds_to_minutes(),
        standard_deviation_of_instantaneous_headway:
          RouteStats.standard_deviation_of_instantaneous_headway(stats_by_route, route)
          |> DTH.seconds_to_minutes(),
        max_headway_deviation:
          RouteStats.max_headway_deviation(stats_by_route, route) |> DTH.seconds_to_minutes(),
        median_headway_deviation:
          RouteStats.median_headway_deviation(stats_by_route, route) |> DTH.seconds_to_minutes(),
        standard_deviation_of_headway_deviation:
          RouteStats.standard_deviation_of_headway_deviation(
            stats_by_route,
            route
          )
          |> DTH.seconds_to_minutes(),
        route_has_cancelled_trip: Enum.member?(state.block_waivered_routes, Route.name(route)),
        route_has_current_alert: Enum.member?(state.routes_with_current_alerts, route)
      }
    end)
  end

  defp format_stats(route, stats_by_route, stats_function) do
    stats_by_route
    |> stats_function.(route)
    |> Enum.sort(:desc)
    |> Enum.map(&DTH.seconds_to_minutes/1)
  end

  defp make_algo_snapshot(module, state, timestamp) do
    algorithm_data = module.snapshot(state.bus_routes, state.stats_by_route)

    samples =
      Enum.map(algorithm_data, fn [
                                    parameters: %{value: value},
                                    routes_with_recommended_alerts: routes_with_recommended_alerts
                                  ] ->
        results =
          prediction_results(
            state.bus_routes,
            state.routes_with_current_alerts,
            routes_with_recommended_alerts
          )

        %{
          value: value,
          balanced_accuracy: PredictionResults.balanced_accuracy(results),
          f_measure: PredictionResults.f_measure(results),
          recall: PredictionResults.recall(results),
          precision: PredictionResults.precision(results)
        }
      end)

    %{
      name: "algorithm snapshot",
      algorithm: module_name(module),
      timestamp: timestamp,
      samples: samples
    }
  end

  defp best_variable_snapshot(algorithm_snapshots, variable, name) do
    timestamp =
      algorithm_snapshots
      |> List.first()
      |> Map.get(:timestamp)

    Enum.into(algorithm_snapshots, %{name: name, timestamp: timestamp}, fn %{
                                                                             algorithm: algorithm,
                                                                             samples: samples
                                                                           } ->
      best =
        samples
        |> Enum.map(&Map.take(&1, [:value, variable]))
        |> Enum.sort_by(& &1[variable], :desc)
        |> hd()

      {algorithm, best}
    end)
  end

  defp schedule_logs do
    Process.send_after(self(), :log, @cadence)
  end

  @spec prediction_results([Route.t()], [Route.t()], [Route.t()]) :: PredictionResults.t()
  defp prediction_results(routes, routes_with_current_alerts, routes_with_recommended_alerts) do
    predictions = Enum.map(routes, &Enum.member?(routes_with_recommended_alerts, &1))
    targets = Enum.map(routes, &Enum.member?(routes_with_current_alerts, &1))

    PredictionResults.new(predictions, targets)
  end

  defp module_name(module) do
    DelayAlertAlgorithm.humane_name(module)
    |> String.replace(" ", "_")
    |> String.downcase()
    |> String.to_atom()
  end

  @spec filtered_by_bus([Alert.t()]) :: [Alert.t()]
  defp filtered_by_bus(alerts), do: Alerts.by_service(alerts, "3")

  @spec filtered_by_delay_type([Alert.t()]) :: [Alert.t()]
  defp filtered_by_delay_type(alerts), do: Alerts.by_effect(alerts, "delay")

  @spec delay_alert?(Route.t(), [Alert.t()]) :: boolean()
  def delay_alert?(%Route{id: route_id}, alerts),
    do: Enum.any?(alerts, &Alert.matches_route_and_effect(&1, route_id, :delay))
end
