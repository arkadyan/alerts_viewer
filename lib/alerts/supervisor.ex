defmodule Alerts.Supervisor do
  @moduledoc """
  Supervisor for the Alerts application. Stream alerts from the API.
  """

  use Supervisor

  @api_params []

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(:ok) do
    children()
    |> Supervisor.init(strategy: :one_for_all)
  end

  defp children() do
    [
      {Phoenix.PubSub, name: Alerts.PubSub}
      | stream_children()
    ]
  end

  defp stream_children() do
    sses_opts =
      Api.Stream.build_options(
        name: Alerts.Api.SSES,
        path: "/alerts",
        params: @api_params
      )

    [
      {Registry, keys: :duplicate, name: :alerts_subscriptions_registry},
      {ServerSentEventStage, sses_opts},
      {Api.Stream, name: Alerts.Api, subscribe_to: Alerts.Api.SSES},
      {Alerts.Stream, subscribe_to: Alerts.Api},
      Alerts.AlertsPubSub
    ]
  end
end
