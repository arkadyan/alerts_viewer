defmodule AlertsViewer.StopRecommendationAlgorithm.MedianHeadwayDeviationDiffComponent do
  @moduledoc """
  Component for controlling the headway diff stop recommendation algorithm.
  """

  @snapshot_min 0
  @snapshot_max 120
  @snapshot_interval 10
  @default_min_value 10

  use AlertsViewer.StopRecommendationAlgorithm.BaseAlgorithmComponents.OneSliderComponent,
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
          min={0}
          max={@snapshot_max}
          step={@snapshot_interval}
          label="Threshold (minutes)"
        />
        <span class="ml-2">
          <%= @min_value %>
        </span>
      </.controls_form>
    </div>
    """
  end

  @spec recommending_closure?(
          Alert.t(),
          non_neg_integer(),
          RouteStats.stats_by_route()
        ) ::
          boolean()
  defp recommending_closure?(alert, threshold_in_minutes, stats_by_route) do
    route_ids = Alert.route_ids(alert)

    median =
      route_ids
      |> Enum.map(fn route_id ->
        RouteStats.median_headway_deviation(
          stats_by_route,
          route_id
        )
      end)
      |> Enum.max()

    !is_nil(median) and median >= threshold_in_minutes * 60
  end
end
