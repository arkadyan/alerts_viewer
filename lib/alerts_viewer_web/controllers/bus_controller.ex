defmodule AlertsViewerWeb.BusController do
  use AlertsViewerWeb, :controller

  alias Alerts.Alert
  alias AlertsViewer.DelayAlertAlgorithm
  alias Routes.{Route, RouteStatsPubSub}

  def snapshot(conn, %{"algorithm" => algorithm}) do
    mod = String.to_existing_atom(algorithm)
    bus_routes = Routes.all_bus_routes()
    stats_by_route = RouteStatsPubSub.all()
    bus_alerts = Alerts.all()
    routes_with_current_alerts = Enum.filter(bus_routes, &delay_alert?(&1, bus_alerts))

    algorithm_data = mod.snapshot(bus_routes, stats_by_route)

    data =
      algorithm_data
      |> Enum.map(fn [
                       parameters: parameters,
                       routes_with_recommended_alerts: routes_with_recommended_alerts
                     ] ->
        results =
          prediction_results(
            bus_routes,
            routes_with_current_alerts,
            routes_with_recommended_alerts
          )

        Map.values(parameters) ++
          [
            PredictionResults.accuracy(results),
            PredictionResults.recall(results),
            PredictionResults.precision(results)
          ]
      end)

    header_row =
      parameter_names(algorithm_data) ++
        [
          "Accuracy",
          "Recall",
          "Precision"
        ]

    data = [header_row | data]

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{csv_file_name(algorithm)}\""
    )
    |> send_resp(200, csv_content(data))
  end

  @spec delay_alert?(Route.t(), [Alert.t()]) :: boolean()
  defp delay_alert?(%Route{id: route_id}, alerts),
    do: Enum.any?(alerts, &Alert.matches_route_and_effect(&1, route_id, :delay))

  @spec prediction_results([Route.t()], [Route.t()], [Route.t()]) :: PredictionResults.t()
  defp prediction_results(routes, routes_with_current_alerts, routes_with_recommended_alerts) do
    predictions = Enum.map(routes, &Enum.member?(routes_with_recommended_alerts, &1))
    targets = Enum.map(routes, &Enum.member?(routes_with_current_alerts, &1))

    PredictionResults.new(predictions, targets)
  end

  defp parameter_names([data_point | _]) do
    Keyword.get(data_point, :parameters)
    |> Map.keys()
    |> Enum.map(fn key ->
      key
      |> Atom.to_string()
      |> String.capitalize()
    end)
  end

  defp parameter_names(_), do: []

  defp csv_file_name(algorithm),
    do: "#{DelayAlertAlgorithm.humane_name(algorithm)}-#{now_string()}.csv"

  defp now_string do
    "Etc/UTC"
    |> DateTime.now!()
    |> DateTime.to_iso8601()
    |> String.replace(":", "-")
  end

  @spec csv_content([[any()]]) :: String.t()
  defp csv_content(data) do
    data
    |> CSV.encode()
    |> Enum.to_list()
    |> to_string()
  end
end
