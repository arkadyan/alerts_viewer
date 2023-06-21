defmodule AlertsViewer.DelayAlertAlgorithm.MedianAndStandardDeviationAdherenceComponent do
  @moduledoc """
  Component for controlling the standard deviation and median delay alert recommendation algorithm.
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
    {:ok, assign(socket, min_std_val: 1200, min_median_val: 1200)}
  end

  @impl true
  def update(assigns, socket) do
    routes_default = Map.get(socket.assigns, :routes, [])
    routes = Map.get(assigns, :routes, routes_default)
    stats_by_route_default = Map.get(socket.assigns, :stats_by_route, %{})
    stats_by_route = Map.get(assigns, :stats_by_route, stats_by_route_default)

    routes_with_recommended_alerts =
      Enum.filter(
        routes,
        &recommending_alert?(
          &1,
          stats_by_route,
          socket.assigns.min_std_val,
          socket.assigns.min_median_val
        )
      )

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
          name="min_median_val"
          value={@min_median_val}
          min={snapshot_min()}
          max={snapshot_max()}
          label="Minumum Median Value"
        />
        <span class="ml-1">
          <%= @min_median_val %>
        </span>
        <div class="pl-16"></div>
        <.input
          type="range"
          name="min_std_val"
          value={@min_std_val}
          min={snapshot_min()}
          max={snapshot_max()}
          label="Minumum Standard Deviation"
        />
        <span class="ml-1">
          <%= @min_std_val %>
        </span>
      </.controls_form>
      <SnapshotButtonComponent.snapshot_button module_name={__MODULE__} />
    </div>
    """
  end

  @impl true
  def handle_event(
        "update-controls",
        %{"min_std_val" => min_std_val_str, "min_median_val" => min_median_val_str},
        socket
      ) do
    min_std_val = String.to_integer(min_std_val_str)
    min_median_val = String.to_integer(min_median_val_str)

    routes_with_recommended_alerts =
      Enum.filter(
        socket.assigns.routes,
        &recommending_alert?(&1, socket.assigns.stats_by_route, min_std_val, min_median_val)
      )

    send(self(), {:updated_routes_with_recommended_alerts, routes_with_recommended_alerts})

    {:noreply, assign(socket, min_std_val: min_std_val, min_median_val: min_median_val)}
  end

  @impl true
  def snapshot(routes, stats_by_route) do
    @snapshot_min..@snapshot_max//@snapshot_interval
    |> Enum.to_list()
    |> Enum.map(fn val ->
      routes_with_recommended_alerts =
        Enum.filter(
          routes,
          &recommending_alert?(&1, stats_by_route, val, val)
        )

      [
        parameters: %{Median_And_Standard_Deviation: val},
        routes_with_recommended_alerts: routes_with_recommended_alerts
      ]
    end)
  end

  @spec recommending_alert?(
          Route.t(),
          RouteStats.stats_by_route(),
          non_neg_integer(),
          non_neg_integer()
        ) ::
          boolean()
  defp recommending_alert?(route, stats_by_route, min_std_val, min_median_val) do
    median = RouteStats.median_schedule_adherence(stats_by_route, route)
    std = RouteStats.standard_deviation_of_schedule_adherence(stats_by_route, route)
    !is_nil(median) and median >= min_median_val && !is_nil(std) and std >= min_std_val
  end

  defp snapshot_min, do: @snapshot_min
  defp snapshot_max, do: @snapshot_max
end
