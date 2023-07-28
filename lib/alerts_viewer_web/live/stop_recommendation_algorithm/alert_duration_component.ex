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
          atom(),
          non_neg_integer(),
          {Keyword.t(), RouteStats.stats_by_route()}
        ) ::
          boolean()
  defp recommending_closure?(route, threshold_in_minutes, {alerts_by_route, _stats_by_route}) do
    current_time = DateTime.now!("America/New_York")
    max = Enum.max(Enum.map(alerts_by_route[route], & &1.created_at), DateTime)
    duration = DateTime.diff(current_time, max, :minute)
    duration >= threshold_in_minutes
  end
end
