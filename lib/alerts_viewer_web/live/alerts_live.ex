defmodule AlertsViewerWeb.AlertsLive do
  @moduledoc """
  LiveView for presenting a list of current alerts.
  """
  use AlertsViewerWeb, :live_view

  alias Alerts.{Alert, AlertsPubSub}

  def mount(_params, _session, socket) do
    alerts = if connected?(socket), do: AlertsPubSub.subscribe(), else: []

    socket = assign(socket, alerts: alerts, update_action: :prepend)

    {:ok, socket, temporary_assigns: [alerts: []]}
  end

  def handle_info({:alerts_reset, alerts}, socket) do
    socket = assign(socket, alerts: alerts, update_action: :replace)

    {:noreply, socket}
  end

  def handle_info({:alerts_added, new_alerts}, socket) do
    socket =
      socket
      |> update(
        :alerts,
        fn alerts -> new_alerts ++ alerts end
      )
      |> assign(:update_action, :prepend)

    {:noreply, socket}
  end

  def handle_info({:alerts_updated, updated_alerts}, socket) do
    socket =
      socket
      |> update(
        :alerts,
        fn alerts -> updated_alerts ++ alerts end
      )
      |> assign(:update_action, :prepend)

    {:noreply, socket}
  end

  def handle_info({:alerts_removed, alert_ids_to_remove}, socket) do
    socket =
      socket
      |> update(
        :alerts,
        fn alerts -> Enum.reject(alerts, &Enum.member?(alert_ids_to_remove, &1)) end
      )
      |> assign(update_action: :replace)

    {:noreply, socket}
  end

  @spec route(Alert.t()) :: String.t()
  def route(%Alert{informed_entity: informed_entity}) do
    informed_entity
    |> Enum.map(&Map.get(&1, :route))
    |> Enum.filter(& &1)
    |> Enum.uniq()
    |> Enum.join(", ")
  end
end
