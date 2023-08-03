defmodule AlertsViewerWeb.AlertsToCloseLive do
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

    alerts =
      if(connected?(socket),
        do: Alerts.subscribe(),
        else: []
      )

    stats_by_route = if(connected?(socket), do: RouteStatsPubSub.subscribe(), else: %{})

    alerts_by_route = alerts_by_route(alerts)

    block_waivered_routes = if(connected?(socket), do: TripUpdatesPubSub.subscribe(), else: [])

    socket =
      assign(socket,
        algorithm_options: algorithm_options,
        current_algorithm: current_algorithm,
        stats_by_route: stats_by_route,
        block_waivered_routes: block_waivered_routes,
        alerts_by_route: alerts_by_route,
        routes_with_recommended_closures: []
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:alerts, alerts}, socket) do
    alerts_by_route = alerts_by_route(alerts)
    {:noreply, assign(socket, alerts_by_route: alerts_by_route)}
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
        {:updated_routes_with_recommended_closures, routes_with_recommended_closures},
        socket
      ) do
    socket =
      assign(socket,
        routes_with_recommended_closures: routes_with_recommended_closures
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-algorithm", %{"algorithm" => module_str}, socket) do
    current_algorithm = String.to_atom(module_str)
    {:noreply, assign(socket, current_algorithm: current_algorithm)}
  end

  @spec alerts_by_route([Alert.t()]) :: keyword([Alert.t()])
  defp alerts_by_route(alerts) do
    alerts
    |> filtered_by_bus()
    |> filtered_by_delay_type()
    |> Alerts.by_route()
    |> Enum.map(fn {route_id, alerts} -> {String.to_atom(route_id), alerts} end)
    |> Enum.sort_by(
      fn {_route_id, alerts} ->
        alerts
        |> Enum.map(& &1.created_at)
        |> Enum.max(DateTime)
      end,
      :asc
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
