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
    alerts_by_route = Map.get(assigns, :alerts_by_route, [])
    stats_by_route = Map.get(assigns, :stats_by_route, %{})

    route_id_atoms = Keyword.keys(alerts_by_route)

    routes_with_recommended_closures =
      Enum.filter(
        route_id_atoms,
        &recommending_closure?(
          &1,
          socket.assigns.duration,
          socket.assigns.median,
          socket.assigns.peak,
          alerts_by_route,
          stats_by_route
        )
      )

    send(
      self(),
      {:updated_routes_with_recommended_closures, routes_with_recommended_closures}
    )

    {:ok,
     assign(socket,
       route_id_atoms: route_id_atoms,
       stats_by_route: stats_by_route,
       alerts_by_route: alerts_by_route
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

    routes_with_recommended_closures =
      Enum.filter(
        socket.assigns.route_id_atoms,
        &recommending_closure?(
          &1,
          duration,
          median,
          peak,
          socket.assigns.alerts_by_route,
          socket.assigns.stats_by_route
        )
      )

    send(
      self(),
      {:updated_routes_with_recommended_closures, routes_with_recommended_closures}
    )

    {:noreply, assign(socket, duration: duration, median: median, peak: peak)}
  end

  @spec recommending_closure?(
          atom(),
          integer(),
          integer(),
          integer(),
          keyword([Alert.t()]),
          RouteStats.stats_by_route()
        ) ::
          boolean()
  defp recommending_closure?(
         route_id_atom,
         duration_threshold_in_minutes,
         median_threshold_in_minutes,
         peak_threshold_in_minutes,
         alerts_by_route,
         stats_by_route
       ) do
    current_time = DateTime.now!("America/New_York")
    route_id = Atom.to_string(route_id_atom)

    max =
      alerts_by_route
      |> Keyword.get(route_id_atom)
      |> Enum.map(& &1.created_at)
      |> Enum.max(DateTime)

    duration = DateTime.diff(current_time, max, :minute)

    median =
      stats_by_route
      |> RouteStats.median_schedule_adherence(route_id)
      |> DateTimeHelpers.seconds_to_minutes()

    peak =
      stats_by_route
      |> RouteStats.max_schedule_adherence(route_id)
      |> DateTimeHelpers.seconds_to_minutes()

    duration >= duration_threshold_in_minutes and
      (!is_nil(median) and median <= median_threshold_in_minutes) and
      (!is_nil(peak) and peak <= peak_threshold_in_minutes)
  end
end
