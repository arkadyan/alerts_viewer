defmodule AlertsViewer.DelayAlertAlgorithm.BaseAlgorithmComponents.OneSliderComponent do
  defmacro __using__(_opts) do
    quote do
      @moduledoc """
      Component for shared functions between algorithm components with one slider.
      """

      use AlertsViewerWeb, :live_component
      alias AlertsViewer.DelayAlertAlgorithm.BaseAlgorithmComponents.SnapshotButtonComponent

      @behaviour AlertsViewer.DelayAlertAlgorithm

      alias Routes.{Route, RouteStats}

      @snapshot_min 50
      @snapshot_max 1500
      @snapshot_interval 50

      @impl true
      def mount(socket) do
        {:ok, assign(socket, min_value: 1200)}
      end

      @impl true
      def update(assigns, socket) do
        routes_default = Map.get(socket.assigns, :routes, [])
        routes = Map.get(assigns, :routes, routes_default)
        stats_by_route_default = Map.get(socket.assigns, :stats_by_route, %{})
        stats_by_route = Map.get(assigns, :stats_by_route, stats_by_route_default)

        routes_with_recommended_alerts =
          Enum.filter(routes, &recommending_alert?(&1, stats_by_route, socket.assigns.min_value))

        send(self(), {:updated_routes_with_recommended_alerts, routes_with_recommended_alerts})

        {:ok, assign(socket, routes: routes, stats_by_route: stats_by_route)}
      end

      @impl true
      def handle_event("update-controls", %{"min_value" => min_value_str}, socket) do
        min_value = String.to_integer(min_value_str)

        routes_with_recommended_alerts =
          Enum.filter(
            socket.assigns.routes,
            &recommending_alert?(&1, socket.assigns.stats_by_route, min_value)
          )

        send(self(), {:updated_routes_with_recommended_alerts, routes_with_recommended_alerts})

        {:noreply, assign(socket, min_value: min_value)}
      end

      @impl true
      def snapshot(routes, stats_by_route) do
        @snapshot_min..@snapshot_max//@snapshot_interval
        |> Enum.to_list()
        |> Enum.map(fn value ->
          routes_with_recommended_alerts =
            Enum.filter(
              routes,
              &recommending_alert?(&1, stats_by_route, value)
            )

          [
            parameters: %{value: value},
            routes_with_recommended_alerts: routes_with_recommended_alerts
          ]
        end)
      end

      defp snapshot_min, do: @snapshot_min
      defp snapshot_max, do: @snapshot_max
    end
  end
end
