defmodule AlertsViewerWeb.BusLive do
  @moduledoc """
  LiveView for presenting a list of bus routes and showing which currently have active alerts.
  """
  use AlertsViewerWeb, :live_view

  alias Alerts.Alert
  alias AlertsViewer.DelayAlertAlgorithm
  alias Routes.{Route, RouteStats, RouteStatsPubSub}

  @impl true
  def mount(_params, _session, socket) do
    delay_alert_algorithm_components =
      Application.get_env(:alerts_viewer, :delay_alert_algorithm_components)

    algorithm_options = algorithm_options(delay_alert_algorithm_components)
    current_algorithm = hd(delay_alert_algorithm_components)

    bus_routes = Routes.all_bus_routes()
    bus_alerts = if(connected?(socket), do: Alerts.subscribe() |> filtered_by_bus(), else: [])
    stats_by_route = if(connected?(socket), do: RouteStatsPubSub.subscribe(), else: %{})

    routes_with_current_alerts = Enum.filter(bus_routes, &delay_alert?(&1, bus_alerts))

    alerts_by_route = Alerts.by_route(bus_alerts)

    socket =
      assign(socket,
        algorithm_options: algorithm_options,
        current_algorithm: current_algorithm,
        filter_rows?: false,
        bus_routes: bus_routes,
        stats_by_route: stats_by_route,
        alerts_by_route: alerts_by_route,
        routes_with_current_alerts: routes_with_current_alerts,
        routes_with_recommended_alerts: [],
        prediction_results: prediction_results(bus_routes, routes_with_current_alerts, [])
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("select-algorithm", %{"algorithm" => module_str}, socket) do
    current_algorithm = String.to_atom(module_str)
    {:noreply, assign(socket, current_algorithm: current_algorithm)}
  end

  @impl true
  def handle_event("set-filter-rows", %{"filter_rows" => filter_rows_str}, socket) do
    filter_rows? = filter_rows_str == "true"
    {:noreply, assign(socket, filter_rows?: filter_rows?)}
  end

  @impl true
  def handle_info({:alerts, alerts}, socket) do
    bus_alerts = filtered_by_bus(alerts)

    routes_with_current_alerts =
      Enum.filter(socket.assigns.bus_routes, &delay_alert?(&1, bus_alerts))

    alerts_by_route = Alerts.by_route(bus_alerts)

    socket =
      assign(socket,
        routes_with_current_alerts: routes_with_current_alerts,
        alerts_by_route: alerts_by_route,
        prediction_results:
          prediction_results(
            socket.assigns.bus_routes,
            routes_with_current_alerts,
            socket.assigns.routes_with_recommended_alerts
          )
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:stats_by_route, stats_by_route}, socket) do
    socket = assign(socket, stats_by_route: stats_by_route)
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:updated_routes_with_recommended_alerts, routes_with_recommended_alerts},
        socket
      ) do
    socket =
      assign(socket,
        routes_with_recommended_alerts: routes_with_recommended_alerts,
        prediction_results:
          prediction_results(
            socket.assigns.bus_routes,
            socket.assigns.routes_with_current_alerts,
            routes_with_recommended_alerts
          )
      )

    {:noreply, socket}
  end

  @spec delay_alert?(Route.t(), [Alert.t()]) :: boolean()
  def delay_alert?(%Route{id: route_id}, alerts),
    do: Enum.any?(alerts, &Alert.matches_route_and_effect(&1, route_id, :delay))

  @doc """
  Display the results of a prediction.

  ## Examples

      <.result prediction={false} target={true} />
  """
  attr(:prediction, :boolean)
  attr(:target, :boolean)

  def result(assigns) do
    ~H"""
    <div class={
      if PredictionResults.true_result?(@prediction, @target),
        do: "text-green-700",
        else: "text-red-700"
    }>
      <%= PredictionResults.to_string(@prediction, @target) %>
    </div>
    """
  end

  def severity_to_minutes(severity) when severity < 3, do: "<10"
  def severity_to_minutes(3), do: "10"
  def severity_to_minutes(4), do: "15"
  def severity_to_minutes(5), do: "20"
  def severity_to_minutes(6), do: "25"
  def severity_to_minutes(7), do: "30"
  def severity_to_minutes(8), do: "30+"
  def severity_to_minutes(severity) when severity >= 9, do: "60+"

  @spec seconds_to_minutes(nil | number) :: nil | float
  def seconds_to_minutes(nil), do: nil

  def seconds_to_minutes(seconds) do
    (seconds / 60) |> Float.round(1)
  end

  def alert_duration(alert) do
    (DateTime.diff(DateTime.now!("America/New_York"), alert.created_at) / 3600)
    |> Float.round(1)
  end

  @spec prediction_results([Route.t()], [Route.t()], [Route.t()]) :: PredictionResults.t()
  defp prediction_results(routes, routes_with_current_alerts, routes_with_recommended_alerts) do
    predictions = Enum.map(routes, &Enum.member?(routes_with_recommended_alerts, &1))
    targets = Enum.map(routes, &Enum.member?(routes_with_current_alerts, &1))

    PredictionResults.new(predictions, targets)
  end

  @type module_option :: {String.t(), module()}
  @spec algorithm_options([module()]) :: [module_option()]
  defp algorithm_options(modules), do: Enum.map(modules, &module_lable_tuple/1)

  @spec module_lable_tuple(module()) :: module_option()
  defp module_lable_tuple(module), do: {DelayAlertAlgorithm.humane_name(module), module}

  @spec filtered_by_bus([Alert.t()]) :: [Alert.t()]
  defp filtered_by_bus(alerts), do: Alerts.by_service(alerts, "3")

  @spec maybe_filtered([Route.t()], boolean(), [Route.t()], [Route.t()]) :: [Route.t()]
  defp maybe_filtered(routes, true, routes_with_current_alerts, routes_with_recommended_alerts) do
    Enum.filter(routes, fn route ->
      Enum.member?(routes_with_current_alerts, route) or
        Enum.member?(routes_with_recommended_alerts, route)
    end)
  end

  defp maybe_filtered(routes, false, _, _), do: routes
end
