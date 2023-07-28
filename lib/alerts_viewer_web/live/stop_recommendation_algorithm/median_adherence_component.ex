defmodule AlertsViewer.StopRecommendationAlgorithm.MedianAdherenceComponent do
  @moduledoc """
  Component for controlling the median adherence stop recommendation algorithm.
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
          atom(),
          non_neg_integer(),
          {Keyword.t(), RouteStats.stats_by_route()}
        ) ::
          boolean()
  defp recommending_closure?(route, threshold_in_minutes, {_alerts_by_route, stats_by_route}) do
    median = RouteStats.median_schedule_adherence(stats_by_route, Atom.to_string(route))
    !is_nil(median) and median >= threshold_in_minutes * 60
  end
end
