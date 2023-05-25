defmodule AlertsViewer.DelayAlertAlgorithm.MedianComponent do
  @moduledoc """
  Component for controlling the Median delay alert recommendation algorithm.
  """

  use AlertsViewerWeb, :live_component

  @behaviour AlertsViewer.DelayAlertAlgorithm

  alias Routes.{Route, RouteStats}

  @snapshot_median_min 50
  @snapshot_median_max 1500
  @snapshot_median_interval 50

  @impl true
  def mount(socket) do
    {:ok, assign(socket, min_median: 1200)}
  end

  @impl true
  def update(assigns, socket) do
    routes_default = Map.get(socket.assigns, :routes, [])
    routes = Map.get(assigns, :routes, routes_default)
    stats_by_route_default = Map.get(socket.assigns, :stats_by_route, %{})
    stats_by_route = Map.get(assigns, :stats_by_route, stats_by_route_default)

    routes_with_recommended_alerts =
      Enum.filter(routes, &recommending_alert?(&1, stats_by_route, socket.assigns.min_median))

    send(self(), {:updated_routes_with_recommended_alerts, routes_with_recommended_alerts})

    {:ok, assign(socket, routes: routes, stats_by_route: stats_by_route)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex space-x-16 items-center">
      <.controls_form phx-change="update-controls" phx-target={@myself}>
        <.input
          type="range"
          name="min_median"
          value={@min_median}
          min={snapshot_median_min()}
          max={snapshot_median_max()}
          label="Minumum Median"
        />
        <span class="ml-2">
          <%= @min_median %>
        </span>
      </.controls_form>

      <.link
        navigate={~p"/bus/snapshot/#{__MODULE__}"}
        replace={false}
        target="_blank"
        class="bg-transparent hover:bg-zinc-500 text-zinc-700 font-semibold hover:text-white py-2 px-4 border border-zinc-500 hover:border-transparent hover:no-underline rounded"
      >
        Snapshot
      </.link>
    </div>
    """
  end

  @impl true
  def handle_event("update-controls", %{"min_median" => min_median_str}, socket) do
    min_median = String.to_integer(min_median_str)

    routes_with_recommended_alerts =
      Enum.filter(
        socket.assigns.routes,
        &recommending_alert?(&1, socket.assigns.stats_by_route, min_median)
      )

    send(self(), {:updated_routes_with_recommended_alerts, routes_with_recommended_alerts})

    {:noreply, assign(socket, min_median: min_median)}
  end

  @impl true
  def snapshot(routes, stats_by_route) do
    @snapshot_median_min..@snapshot_median_max//@snapshot_median_interval
    |> Enum.to_list()
    |> Enum.map(fn median ->
      routes_with_recommended_alerts =
        Enum.filter(
          routes,
          &recommending_alert?(&1, stats_by_route, median)
        )

      [
        parameters: %{median: median},
        routes_with_recommended_alerts: routes_with_recommended_alerts
      ]
    end)
  end

  @spec recommending_alert?(Route.t(), RouteStats.stats_by_route(), non_neg_integer()) ::
          boolean()
  defp recommending_alert?(route, stats_by_route, min_median) do
    median = RouteStats.median_schedule_adherence(stats_by_route, route)
    !is_nil(median) and median >= min_median
  end

  defp snapshot_median_min, do: @snapshot_median_min
  defp snapshot_median_max, do: @snapshot_median_max
end
