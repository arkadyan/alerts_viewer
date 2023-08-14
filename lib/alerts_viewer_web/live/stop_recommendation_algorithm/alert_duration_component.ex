defmodule AlertsViewer.StopRecommendationAlgorithm.AlertDurationComponent do
  @moduledoc """
  Component for controlling the alert duration stop recommendation algorithm.
  """

  @snapshot_min 0
  @snapshot_max 360
  @snapshot_interval 15
  @default_min_value 60

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
  defp recommending_closure?(alert, threshold_in_minutes, _stats_by_route) do
    duration = DateTime.diff(DateTime.now!("America/New_York"), alert.created_at, :minute)
    duration >= threshold_in_minutes
  end
end
