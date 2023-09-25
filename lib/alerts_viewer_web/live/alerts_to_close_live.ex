defmodule AlertsViewerWeb.AlertsToCloseLive do
  @moduledoc """
  LiveView for displaying alerts that we can maybe close.
  """
  use AlertsViewerWeb, :live_view
  alias Alerts.Alert
  alias AlertsViewerWeb.DateTimeHelpers
  alias Routes.{Route, RouteStats, RouteStatsPubSub}
  alias TripUpdates.TripUpdatesPubSub

  @max_alert_duration 60
  @min_peak_headway 15

  @impl true
  def mount(_params, _session, socket) do
    bus_routes = Routes.all_bus_routes()

    alerts =
      if(connected?(socket),
        do: Alerts.subscribe(),
        else: []
      )

    stats_by_route = if(connected?(socket), do: RouteStatsPubSub.subscribe(), else: %{})

    sorted_alerts = sorted_alerts(alerts)

    block_waivered_routes = if(connected?(socket), do: TripUpdatesPubSub.subscribe(), else: [])

    recommended_closures = recommended_closures(sorted_alerts, stats_by_route)

    socket =
      assign(socket,
        stats_by_route: stats_by_route,
        bus_routes: bus_routes,
        block_waivered_routes: block_waivered_routes,
        sorted_alerts: sorted_alerts,
        alerts_with_recommended_closures: recommended_closures
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:alerts, alerts}, socket) do
    sorted_alerts = sorted_alerts(alerts)

    recommended_closures = recommended_closures(sorted_alerts, socket.assigns.stats_by_route)

    {:noreply,
     assign(socket,
       sorted_alerts: sorted_alerts,
       alerts_with_recommended_closures: recommended_closures
     )}
  end

  @impl true
  def handle_info({:stats_by_route, stats_by_route}, socket) do
    recommended_closures = recommended_closures(socket.assigns.sorted_alerts, stats_by_route)

    {:noreply,
     assign(socket,
       stats_by_route: stats_by_route,
       alerts_with_recommended_closures: recommended_closures
     )}
  end

  @impl true
  def handle_info({:block_waivered_routes, block_waivered_routes}, socket) do
    {:noreply, assign(socket, block_waivered_routes: block_waivered_routes)}
  end

  def recommended_closures(alerts, stats_by_route) do
    Enum.filter(
      alerts,
      &recommending_closure?(
        &1,
        @max_alert_duration,
        @min_peak_headway,
        stats_by_route
      )
    )
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

  @spec recommending_closure?(
          Alert.t(),
          integer(),
          integer(),
          RouteStats.stats_by_route()
        ) ::
          boolean()
  defp recommending_closure?(
         alert,
         duration_threshold_in_minutes,
         peak_threshold_in_minutes,
         stats_by_route
       ) do
    current_time = DateTime.now!("America/New_York")
    route_ids = Alert.route_ids(alert)

    duration = DateTime.diff(current_time, alert.created_at, :minute)

    headways =
      route_ids
      |> Enum.map(fn route_id ->
        stats_by_route
        |> RouteStats.max_headway_deviation(route_id)
        |> DateTimeHelpers.seconds_to_minutes()
      end)
      |> Enum.reject(&is_nil/1)

    peak =
      case headways do
        [_ | _] -> Enum.max(headways)
        [] -> nil
      end

    duration >= duration_threshold_in_minutes and
      (!is_nil(peak) and peak <= peak_threshold_in_minutes)
  end

  @spec severity_to_minutes(integer()) :: String.t()
  def severity_to_minutes(severity) when severity < 3, do: "<10"
  def severity_to_minutes(3), do: "10"
  def severity_to_minutes(4), do: "15"
  def severity_to_minutes(5), do: "20"
  def severity_to_minutes(6), do: "25"
  def severity_to_minutes(7), do: "30"
  def severity_to_minutes(8), do: "30+"
  def severity_to_minutes(severity) when severity >= 9, do: "60+"
end
