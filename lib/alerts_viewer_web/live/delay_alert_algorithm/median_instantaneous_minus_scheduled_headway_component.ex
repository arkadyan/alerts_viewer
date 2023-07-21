defmodule AlertsViewer.DelayAlertAlgorithm.MedianInstantaneousMinusScheduledHeadwayComponent do
  @moduledoc """
  Component for controlling the Median delay alert recommendation algorithm.
  """

  @snapshot_min 50
  @snapshot_max 1500
  @snapshot_interval 50
  @default_min_value 1200

  use AlertsViewer.DelayAlertAlgorithm.BaseAlgorithmComponents.OneSliderComponent,
    snapshot_min: @snapshot_min,
    snapshot_max: @snapshot_max,
    snapshot_interval: @snapshot_interval,
    min_value: @default_min_value

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex space-x-16 items-center">
      <.controls_form phx-change="update-controls" phx-target={@myself}>
        <.input
          type="range"
          name="min_value"
          value={@min_value}
          min={@snapshot_min}
          max={@snapshot_max}
          label="Minumum Median Instantaneous - Scheduled Headway"
        />
        <span class="ml-2">
          <%= @min_value %>
        </span>
      </.controls_form>
      <SnapshotButtonComponent.snapshot_button module_name={__MODULE__} />
    </div>
    """
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

  @spec recommending_alert?(Route.t(), RouteStats.stats_by_route(), non_neg_integer()) ::
          boolean()
  defp recommending_alert?(route, stats_by_route, min_value) do
    median = RouteStats.median_instantaneous_minus_scheduled_headway(stats_by_route, route)
    !is_nil(median) and median >= min_value
  end
end
