defmodule AlertsViewerWeb.BusLive do
  @moduledoc """
  LiveView for presenting a list of bus routes and showing which currently have active alerts.
  """
  use AlertsViewerWeb, :live_view

  alias Alerts.Alert
  alias Routes.{Route, RouteStats, RouteStatsPubSub}

  @impl true
  def mount(_params, _session, socket) do
    bus_routes = Routes.all_bus_routes()
    bus_alerts = if(connected?(socket), do: Alerts.subscribe() |> filtered_by_bus(), else: [])
    stats_by_route = if(connected?(socket), do: RouteStatsPubSub.subscribe(), else: %{})

    socket =
      assign(socket,
        bus_routes: bus_routes,
        bus_alerts: bus_alerts,
        stats_by_route: stats_by_route
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:alerts, alerts}, socket) do
    socket = assign(socket, bus_alerts: filtered_by_bus(alerts))
    {:noreply, socket}
  end

  @impl true
  def handle_info({:stats_by_route, stats_by_route}, socket) do
    socket = assign(socket, stats_by_route: stats_by_route)
    {:noreply, socket}
  end

  @spec delay_alert?(Route.t(), [Alert.t()]) :: boolean()
  def delay_alert?(route, alerts), do: delay_alert_count(route, alerts) > 0

  @spec delay_alert_count(Route.t(), [Alert.t()]) :: non_neg_integer()
  def delay_alert_count(%Route{id: route_id}, alerts),
    do: Enum.count(alerts, &Alert.matches_route_and_effect(&1, route_id, :delay))

  @spec individual_vehicles_for_route(RouteStatsPubSub.stats_by_route(), Route.t()) :: String.t()
  def individual_vehicles_for_route(stats_by_route, %Route{id: route_id}) do
    stats_by_route
    |> schedule_adherence_secs_for_route_for_route(route_id)
    |> Enum.join(", ")
  end

  @spec median_schedule_adherence(RouteStatsPubSub.stats_by_route(), Route.t()) :: number()
  def median_schedule_adherence(stats_by_route, %Route{id: route_id}) do
    stats_by_route
    |> schedule_adherence_secs_for_route_for_route(route_id)
    |> Statistics.median()
    |> round_to_1_place()
  end

  @spec standard_deviation_of_schedule_adherence(RouteStatsPubSub.stats_by_route(), Route.t()) ::
          number()
  def standard_deviation_of_schedule_adherence(stats_by_route, %Route{id: route_id}) do
    stats_by_route
    |> schedule_adherence_secs_for_route_for_route(route_id)
    |> Statistics.stdev()
    |> round_to_1_place()
  end

  # Temporary "fake" algorithm just to get something on the screen
  @spec suggesting_alert?(Route.t()) :: boolean()
  def suggesting_alert?(%Route{id: route_id}), do: String.starts_with?(route_id, "1")

  @spec error_icon(Route.t(), [Alert.t()]) :: String.t()
  def error_icon(route, alerts) do
    case error(route, alerts) do
      :pos ->
        "➕"

      :neg ->
        "➖"

      :none ->
        ""
    end
  end

  # False positive, false negative, or none
  @type error_type :: :pos | :neg | :none
  @spec error(Route.t(), [Alert.t()]) :: error_type()
  def error(route, alerts) do
    case {delay_alert?(route, alerts), suggesting_alert?(route)} do
      {true, false} ->
        :neg

      {false, true} ->
        :pos

      _ ->
        :none
    end
  end

  @spec filtered_by_bus([Alert.t()]) :: [Alert.t()]
  defp filtered_by_bus(alerts), do: Alerts.by_service(alerts, "3")

  @spec schedule_adherence_secs_for_route_for_route(RouteStatsPubSub.stats_by_route(), Route.id()) ::
          [
            integer()
          ]
  defp schedule_adherence_secs_for_route_for_route(stats_by_route, route_id) do
    case Map.get(stats_by_route, route_id) do
      nil ->
        []

      route_stats ->
        RouteStats.vehicles_schedule_adherence_secs(route_stats)
    end
  end

  @spec round_to_1_place(number() | nil) :: number() | nil
  defp round_to_1_place(int) when is_integer(int), do: int
  defp round_to_1_place(num) when is_number(num), do: Float.round(num, 1)
  defp round_to_1_place(_), do: nil
end
