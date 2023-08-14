defmodule AlertsViewerWeb.OpenDelayAlertsLive do
  @moduledoc """
  LiveView for displaying alerts that we can maybe close.
  """
  use AlertsViewerWeb, :live_view
  alias Alerts.Alert
  alias Routes.{Route, RouteStats, RouteStatsPubSub}
  alias TripUpdates.TripUpdatesPubSub

  @impl true
  def mount(_params, _session, socket) do
    stop_recommendation_algorithm_components =
      Application.get_env(:alerts_viewer, :stop_recommendation_algorithm_components)

    algorithm_options = algorithm_options(stop_recommendation_algorithm_components)
    current_algorithm = hd(stop_recommendation_algorithm_components)

    bus_routes = Routes.all_bus_routes()

    alerts =
      if(connected?(socket),
        do: Alerts.subscribe(),
        else: []
      )

    stats_by_route = if(connected?(socket), do: RouteStatsPubSub.subscribe(), else: %{})

    sorted_alerts = sorted_alerts(alerts)

    block_waivered_routes = if(connected?(socket), do: TripUpdatesPubSub.subscribe(), else: [])

    socket =
      assign(socket,
        algorithm_options: algorithm_options,
        current_algorithm: current_algorithm,
        stats_by_route: stats_by_route,
        bus_routes: bus_routes,
        block_waivered_routes: block_waivered_routes,
        sorted_alerts: sorted_alerts,
        alerts_with_recommended_closures: []
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:alerts, alerts}, socket) do
    sorted_alerts = sorted_alerts(alerts)

    {:noreply,
     assign(socket, sorted_alerts: sorted_alerts, alerts_by_route: Alerts.by_route(sorted_alerts))}
  end

  @impl true
  def handle_info({:stats_by_route, stats_by_route}, socket) do
    {:noreply, assign(socket, stats_by_route: stats_by_route)}
  end

  @impl true
  def handle_info({:block_waivered_routes, block_waivered_routes}, socket) do
    {:noreply, assign(socket, block_waivered_routes: block_waivered_routes)}
  end

  @impl true
  def handle_info(
        {:updated_alerts_with_recommended_closures, alerts_with_recommended_closures},
        socket
      ) do
    socket =
      assign(socket,
        alerts_with_recommended_closures: alerts_with_recommended_closures
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-algorithm", %{"algorithm" => module_str}, socket) do
    current_algorithm = String.to_atom(module_str)
    {:noreply, assign(socket, current_algorithm: current_algorithm)}
  end

  @spec route_names_from_alert(Alert.t(), [Route.t()]) :: [String.t()]
  def route_names_from_alert(alert, bus_routes) do
    alert
    |> Alert.route_ids()
    |> Enum.map(&Routes.get_by_id(bus_routes, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Route.name/1)
  end

  @spec sorted_alerts([Alert.t()]) :: [Alert.t()]
  defp sorted_alerts(alerts) do
    alerts
    |> filtered_by_bus()
    |> filtered_by_delay_type()
    |> Enum.sort_by(
      & &1.created_at,
      {:asc, DateTime}
    )
  end

  @spec delay_alert?(Route.t(), [Alert.t()]) :: boolean()
  def delay_alert?(%Route{id: route_id}, alerts),
    do: Enum.any?(alerts, &Alert.matches_route_and_effect(&1, route_id, :delay))

  @spec filtered_by_bus([Alert.t()]) :: [Alert.t()]
  defp filtered_by_bus(alerts), do: Alerts.by_service(alerts, "3")

  @spec filtered_by_delay_type([Alert.t()]) :: [Alert.t()]
  defp filtered_by_delay_type(alerts), do: Alerts.by_effect(alerts, "delay")

  @type module_option :: {String.t(), module()}
  @spec algorithm_options([module()]) :: [module_option()]
  defp algorithm_options(modules), do: Enum.map(modules, &module_lable_tuple/1)

  @spec module_lable_tuple(module()) :: module_option()
  defp module_lable_tuple(module),
    do: {AlertsViewer.DelayAlertAlgorithm.humane_name(module), module}
end
