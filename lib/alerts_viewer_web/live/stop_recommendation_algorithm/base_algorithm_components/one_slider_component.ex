defmodule AlertsViewer.StopRecommendationAlgorithm.BaseAlgorithmComponents.OneSliderComponent do
  defmacro __using__(opts) do
    snapshot_min = Keyword.get(opts, :snapshot_min)
    snapshot_max = Keyword.get(opts, :snapshot_max)
    snapshot_interval = Keyword.get(opts, :snapshot_interval)
    min_value = Keyword.get(opts, :min_value)

    quote do
      @moduledoc """
      Component for shared functions between algorithm components with one slider.
      """

      use AlertsViewerWeb, :live_component

      alias Alerts.Alert
      alias Routes.{Route, RouteStats}

      @impl true
      def mount(socket) do
        socket =
          assign(
            socket,
            snapshot_min: unquote(snapshot_min),
            snapshot_max: unquote(snapshot_max),
            snapshot_interval: unquote(snapshot_interval),
            min_value: unquote(min_value)
          )

        {:ok, socket}
      end

      @impl true
      def update(assigns, socket) do
        stats_by_route = Map.get(assigns, :stats_by_route, %{})
        alerts = Map.get(assigns, :alerts, [])
        routes = Map.keys(stats_by_route)

        alerts_with_recommended_closures =
          Enum.filter(
            alerts,
            &recommending_closure?(
              &1,
              socket.assigns.min_value,
              stats_by_route
            )
          )

        send(
          self(),
          {:updated_alerts_with_recommended_closures, alerts_with_recommended_closures}
        )

        {:ok,
         assign(socket,
           routes: routes,
           stats_by_route: stats_by_route,
           alerts: alerts
         )}
      end

      @impl true
      def handle_event("update-controls", %{"min_value" => min_value_str}, socket) do
        min_value = String.to_integer(min_value_str)

        alerts_with_recommended_closures =
          Enum.filter(
            socket.assigns.alerts,
            &recommending_closure?(
              &1,
              min_value,
              socket.assigns.stats_by_route
            )
          )

        send(
          self(),
          {:updated_alerts_with_recommended_closures, alerts_with_recommended_closures}
        )

        {:noreply, assign(socket, min_value: min_value)}
      end
    end
  end
end
