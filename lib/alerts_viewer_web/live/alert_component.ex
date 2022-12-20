defmodule AlertsViewerWeb.AlertComponent do
  @moduledoc """
  Component for rendering an Alert with all of its details.
  """

  use AlertsViewerWeb, :live_component

  # alias Alerts.Alert

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header><%= @title %></.header>

      <.list>
        <:item title="Short Header"><%= @alert.short_header %></:item>
        <:item title="Header"><%= @alert.header %></:item>
        <:item title="Description"><%= @alert.description %></:item>
        <:item title="Banner"><%= @alert.banner %></:item>
        <:item title="URL"><%= @alert.url %></:item>
        <:item title="Effect"><%= humanized_atom(@alert.effect) %></:item>
        <:item title="Service Effect"><%= @alert.service_effect %></:item>
        <:item title="Cause"><%= humanized_atom(@alert.cause) %></:item>
        <:item title="Lifecycle"><%= humanized_atom(@alert.lifecycle) %></:item>
        <:item title="Timeframe"><%= @alert.timeframe %></:item>
        <:item title="Severity"><%= @alert.severity %></:item>
        <:item title="Active Period">
          <.list_active_periods active_periods={@alert.active_period} />
        </:item>
        <:item title="informed_entity">
          <div :for={informed_entity <- @alert.informed_entity}>
            <%= inspect(informed_entity) %>
          </div>
        </:item>/
        <:item title="Created At">
          <.date_time date_time={@alert.created_at} /> (<%= @alert.created_at %>)
        </:item>
        <:item title="Updated At">
          <.date_time date_time={@alert.updated_at} /> (<%= @alert.updated_at %>)
        </:item>
      </.list>
    </div>
    """
  end

  @doc """
  Renders a list of alert active periods using human-friendly formatting.
  """
  attr :active_periods, :list, required: true

  def list_active_periods(assigns) do
    ~H"""
    <ol>
      <li :for={{starting_dt, endind_dt} <- @active_periods} class="whitespace-nowrap">
        <.date_time date_time={starting_dt} /> – <.date_time date_time={endind_dt} />
        (<%= starting_dt %> – <%= endind_dt %>)
      </li>
    </ol>
    """
  end
end
