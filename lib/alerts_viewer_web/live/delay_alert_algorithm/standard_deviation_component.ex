defmodule AlertsViewer.DelayAlertAlgorithm.StandardDeviationComponent do
  @moduledoc """
  Component for controlling the standard deviation delay alert recommendation algorithm.
  """

  use AlertsViewerWeb, :live_component

  @behaviour AlertsViewer.DelayAlertAlgorithm

  alias Routes.{Route, RouteStats}

  @snapshot_std_min 50
  @snapshot_std_max 1500
  @snapshot_std_interval 50

  @impl true
  def mount(socket) do
    {:ok, assign(socket, min_std: 10)}
  end

  @impl true
  def update(assigns, socket) do
    routes_default = Map.get(socket.assigns, :routes, [])
    routes = Map.get(assigns, :routes, routes_default)
    stats_by_route_default = Map.get(socket.assigns, :stats_by_route, %{})
    stats_by_route = Map.get(assigns, :stats_by_route, stats_by_route_default)

    routes_with_recommended_alerts =
      Enum.filter(routes, &recommending_alert?(&1, stats_by_route, socket.assigns.min_std))

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
          name="min_std"
          value={@min_std}
          min={snapshot_std_min()}
          max={snapshot_std_max()}
          label="Minumum Standard Deviation"
        />
        <span class="ml-2">
          <%= @min_std %>
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
  def handle_event("update-controls", %{"min_std" => min_std_str}, socket) do
    min_std = String.to_integer(min_std_str)

    routes_with_recommended_alerts =
      Enum.filter(
        socket.assigns.routes,
        &recommending_alert?(&1, socket.assigns.stats_by_route, min_std)
      )

    send(self(), {:updated_routes_with_recommended_alerts, routes_with_recommended_alerts})

    {:noreply, assign(socket, min_std: min_std)}
  end

  @impl true
  def snapshot(routes, stats_by_route) do
    @snapshot_std_min..@snapshot_std_max//@snapshot_std_interval
    |> Enum.to_list()
    |> Enum.map(fn std ->
      routes_with_recommended_alerts =
        Enum.filter(
          routes,
          &recommending_alert?(&1, stats_by_route, std)
        )

      [
        parameters: %{std: std},
        routes_with_recommended_alerts: routes_with_recommended_alerts
      ]
    end)
  end

  @spec recommending_alert?(Route.t(), RouteStats.stats_by_route(), non_neg_integer()) ::
          boolean()
  defp recommending_alert?(route, stats_by_route, min_std) do
    std = RouteStats.standard_deviation_of_schedule_adherence(stats_by_route, route)
    !is_nil(std) and std >= min_std
  end

  defp snapshot_std_min, do: @snapshot_std_min
  defp snapshot_std_max, do: @snapshot_std_max
end
