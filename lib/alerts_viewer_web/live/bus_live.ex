defmodule AlertsViewerWeb.BusLive do
  @moduledoc """
  LiveView for presenting a list of bus routes and showing which currently have active alerts.
  """
  use AlertsViewerWeb, :live_view

  alias Alerts.Alert
  alias Routes.Route

  @impl true
  def mount(_params, _session, socket) do
    bus_routes = Routes.all_bus_routes()
    bus_alerts = if(connected?(socket), do: Alerts.subscribe() |> filtered_by_bus(), else: [])

    socket = assign(socket, bus_routes: bus_routes, bus_alerts: bus_alerts)
    {:ok, socket}
  end

  @impl true
  def handle_info({:alerts, alerts}, socket) do
    socket = assign(socket, bus_alerts: filtered_by_bus(alerts))
    {:noreply, socket}
  end

  @spec current_alert?(Route.t(), [Alert.t()]) :: boolean()
  def current_alert?(%Route{id: route_id}, alerts) do
    Enum.any?(alerts, &Alert.matches_route(&1, route_id))
  end

  @spec filtered_by_bus([Alert.t()]) :: [Alert.t()]
  defp filtered_by_bus(alerts), do: Alerts.by_service(alerts, "3")
end
