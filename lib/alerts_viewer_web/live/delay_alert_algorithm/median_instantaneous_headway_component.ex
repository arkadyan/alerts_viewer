defmodule AlertsViewer.DelayAlertAlgorithm.MedianInstantaneousHeadwayComponent do
  use AlertsViewer.DelayAlertAlgorithm.BaseAlgorithmComponents.OneSliderComponent

  @moduledoc """
  Component for controlling the Median delay alert recommendation algorithm.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex space-x-16 items-center">
      <.controls_form phx-change="update-controls" phx-target={@myself}>
        <.input
          type="range"
          name="min_value"
          value={@min_value}
          min={snapshot_min()}
          max={snapshot_max()}
          label="Minumum Median Instantaneous Headway"
        />
        <span class="ml-2">
          <%= @min_value %>
        </span>
      </.controls_form>
      <SnapshotButtonComponent.snapshot_button module_name={__MODULE__} />
    </div>
    """
  end

  @spec recommending_alert?(Route.t(), RouteStats.stats_by_route(), non_neg_integer()) ::
          boolean()
  defp recommending_alert?(route, stats_by_route, min_value) do
    median = RouteStats.median_instantaneous_headway(stats_by_route, route)
    !is_nil(median) and median >= min_value
  end
end
