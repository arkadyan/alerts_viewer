defmodule AlertsViewerWeb.AlertsLive do
  @moduledoc """
  LiveView for presenting a list of current alerts.
  """
  use AlertsViewerWeb, :live_view

  alias Alerts.Alert

  def mount(_params, _session, socket) do
    alerts = if(connected?(socket), do: Alerts.subscribe(), else: [])
    socket = update_alerts_and_filter(socket, alerts, effect: "")
    {:ok, socket}
  end

  def handle_info({:alerts, alerts}, %{assigns: %{effect: effect}} = socket) do
    socket = update_alerts_and_filter(socket, alerts, effect: effect)
    {:noreply, socket}
  end

  def handle_event("filter", %{"effect" => effect_input}, socket) do
    effect = if effect_input == "All Effects", do: "", else: effect_input
    socket = update_alerts_and_filter(socket, Alerts.all(), effect: effect)
    {:noreply, socket}
  end

  @spec effect_filter_options() :: [tuple()]
  def effect_filter_options() do
    Alerts.Alert.all_effects()
    |> Enum.map(fn effect_atom -> {humanized_effect_name(effect_atom), effect_atom} end)
  end

  @doc """
  Return a human-friendly name for an effect atom.

  iex> AlertsViewerWeb.AlertsLive.humanized_effect_name(:delay)
  "Delay"
  iex> AlertsViewerWeb.AlertsLive.humanized_effect_name(:service_change)
  "Service Change"
  """
  @spec humanized_effect_name(atom) :: String.t()
  def humanized_effect_name(effect_atom) do
    effect_atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @spec update_alerts_and_filter(Phoenix.LiveView.Socket.t(), [Alert.t()], keyword()) ::
          Phoenix.LiveView.Socket.t()
  defp update_alerts_and_filter(socket, alerts, filter_params) do
    alerts = filtered(alerts, filter_params)
    assign(socket, filter_params ++ [alerts: alerts])
  end

  @spec filtered([Alert.t()], keyword()) :: [Alert.t()]
  defp filtered(alerts, effect: effect) do
    alerts
    |> by_effect(effect)
  end

  @spec by_effect([Alert.t()], String.t()) :: [Alert.t()]
  defp by_effect(alerts, ""), do: alerts

  defp by_effect(alerts, effect) do
    effect_atom = String.to_atom(effect)
    Enum.filter(alerts, &(&1.effect == effect_atom))
  end
end
