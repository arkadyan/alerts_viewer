defmodule AlertsViewer.StopRecommendationAlgorithm.AdherenceComponent do
  @moduledoc """
  Component for controlling the adherence stop recommendation algorithm.
  """

  use AlertsViewerWeb, :live_component

  alias Alerts.Alert
  alias AlertsViewerWeb.DateTimeHelpers
  alias Routes.RouteStats

  @impl true
  def mount(socket) do
    socket =
      assign(
        socket,
        duration_min: 0,
        duration_max: 360,
        duration_interval: 5,
        duration: 60,
        median_min: 0,
        median_max: 120,
        median_interval: 5,
        median: 10,
        peak_min: 0,
        peak_max: 120,
        peak_interval: 5,
        peak: 10
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    alerts = Map.get(assigns, :alerts, [])
    stats_by_route = Map.get(assigns, :stats_by_route, %{})

    alerts_with_recommended_closures =
      Enum.filter(
        socket.assigns.alerts,
        &recommending_closure?(
          &1,
          socket.assigns.duration,
          socket.assigns.median,
          socket.assigns.peak,
          stats_by_route
        )
      )

    send(
      self(),
      {:updated_alerts_with_recommended_closures, alerts_with_recommended_closures}
    )

    {:ok,
     assign(socket,
       stats_by_route: stats_by_route,
       alerts: alerts
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex space-x-16 items-center">
      <.controls_form phx-change="update-controls" phx-target={@myself}>
        <.input
          type="range"
          name="duration"
          value={@duration}
          min={@duration_min}
          max={@duration_max}
          step={@duration_interval}
          label="Duration (minutes)"
        />
        <span class="ml-2">
          <%= @duration %>
        </span>

        <div class="pl-16"></div>

        <.input
          type="range"
          name="median"
          value={@median}
          min={@median_min}
          max={@median_max}
          step={@median_interval}
          label="Median Adherence (minutes)"
        />
        <span class="ml-1">
          <%= @median %>
        </span>

        <div class="pl-16"></div>

        <.input
          type="range"
          name="peak"
          value={@peak}
          min={@peak_min}
          max={@peak_max}
          step={@peak_interval}
          label="Peak Adherence (minutes)"
        />
        <span class="ml-1">
          <%= @peak %>
        </span>
      </.controls_form>
    </div>
    """
  end

  @impl true
  def handle_event(
        "update-controls",
        %{"duration" => duration_str, "median" => median_str, "peak" => peak_str},
        socket
      ) do
    duration = String.to_integer(duration_str)
    median = String.to_integer(median_str)
    peak = String.to_integer(peak_str)

    alerts_with_recommended_closures =
      Enum.filter(
        socket.assigns.alerts,
        &recommending_closure?(
          &1,
          duration,
          median,
          peak,
          socket.assigns.stats_by_route
        )
      )

    send(
      self(),
      {:updated_alerts_with_recommended_closures, alerts_with_recommended_closures}
    )

    {:noreply, assign(socket, duration: duration, median: median, peak: peak)}
  end

  @spec recommending_closure?(
          Alert.t(),
          integer(),
          integer(),
          integer(),
          RouteStats.stats_by_route()
        ) ::
          boolean()
  defp recommending_closure?(
         alert,
         duration_threshold_in_minutes,
         median_threshold_in_minutes,
         peak_threshold_in_minutes,
         stats_by_route
       ) do
    current_time = DateTime.now!("America/New_York")
    route_ids = Alert.route_ids(alert)

    duration = DateTime.diff(current_time, alert.created_at, :minute)

    median =
      route_ids
      |> Enum.map(fn route_id ->
        stats_by_route
        |> RouteStats.median_schedule_adherence(route_id)
        |> DateTimeHelpers.seconds_to_minutes()
      end)
      |> Enum.max()

    peak =
      route_ids
      |> Enum.map(fn route_id ->
        stats_by_route
        |> RouteStats.max_schedule_adherence(route_id)
        |> DateTimeHelpers.seconds_to_minutes()
      end)
      |> Enum.max()

    duration >= duration_threshold_in_minutes and
      (!is_nil(median) and median <= median_threshold_in_minutes) and
      (!is_nil(peak) and peak <= peak_threshold_in_minutes)
  end
end
