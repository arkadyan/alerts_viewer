defmodule AlertsViewerWeb.AlertsLive do
  @moduledoc """
  LiveView for presenting a list of current alerts.
  """
  use AlertsViewerWeb, :live_view

  import AlertsViewerWeb.StringHelpers, only: [humanized_atom: 1]

  alias Alerts.Alert

  @impl true
  def mount(_params, _session, socket) do
    alerts = if(connected?(socket), do: Alerts.subscribe(), else: [])
    socket = update_alerts_and_filter(socket, alerts, effect: "", service: "")
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case Alerts.get(id) do
      {:ok, alert} ->
        socket
        |> assign(:page_title, "Alert #{id}")
        |> assign(:alert, alert)

      :not_found ->
        socket
        |> put_flash(:error, "Alert not found")
        |> redirect(to: ~p"/alerts")
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Alerts")
    |> assign(:alert, nil)
  end

  @impl true
  def handle_info({:alerts, alerts}, %{assigns: %{effect: effect, service: service}} = socket) do
    socket = update_alerts_and_filter(socket, alerts, effect: effect, service: service)
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"effect" => effect_input, "service" => service_input}, socket) do
    effect = if effect_input == "All Effects", do: "", else: effect_input
    service = if service_input == "All Service Types", do: "", else: service_input
    socket = update_alerts_and_filter(socket, Alerts.all(), effect: effect, service: service)
    {:noreply, socket}
  end

  @spec effect_filter_options :: [tuple()]
  def effect_filter_options do
    Alerts.Alert.all_effects()
    |> Enum.map(fn effect_atom -> {humanized_atom(effect_atom), effect_atom} end)
  end

  @spec update_alerts_and_filter(Phoenix.LiveView.Socket.t(), [Alert.t()], keyword()) ::
          Phoenix.LiveView.Socket.t()
  defp update_alerts_and_filter(socket, alerts, filter_params) do
    alerts = filtered(alerts, filter_params)
    assign(socket, filter_params ++ [alerts: alerts])
  end

  @spec filtered([Alert.t()], keyword()) :: [Alert.t()]
  defp filtered(alerts, effect: effect, service: service) do
    alerts
    |> by_effect(effect)
    |> by_service(service)
  end

  @spec by_effect([Alert.t()], String.t()) :: [Alert.t()]
  defp by_effect(alerts, ""), do: alerts

  defp by_effect(alerts, effect) do
    effect_atom = String.to_atom(effect)
    Enum.filter(alerts, &(&1.effect == effect_atom))
  end

  @spec by_service([Alert.t()], String.t()) :: [Alert.t()]
  defp by_service(alerts, ""), do: alerts

  defp by_service(alerts, "access"),
    do: Enum.filter(alerts, &Alert.matches_service_type(&1, :access))

  defp by_service(alerts, route_type_string),
    do: Enum.filter(alerts, &Alert.matches_service_type(&1, String.to_integer(route_type_string)))
end
