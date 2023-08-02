defmodule AlertsViewer.DelayAlertAlgorithm.StandardDeviationHeadwayDeviationComponent do
  @moduledoc """
  Component for controlling the standard deviation delay alert recommendation algorithm.
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
          label="Minumum Standard Deviation of Headway Deviation"
        />
        <span class="ml-2">
          <%= @min_value %>
        </span>
      </.controls_form>
    </div>
    """
  end

  @spec recommending_alert?(Route.t(), RouteStats.stats_by_route(), non_neg_integer()) ::
          boolean()
  defp recommending_alert?(route, stats_by_route, min_value) do
    std =
      RouteStats.standard_deviation_of_headway_deviation(
        stats_by_route,
        route
      )

    !is_nil(std) and std >= min_value
  end
end
