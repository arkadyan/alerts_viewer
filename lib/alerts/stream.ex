defmodule Alerts.Stream do
  @moduledoc """
  Handle streamed alerts data coming from the Api. Receive them and broadcast them over pub-sub.
  """

  use GenStage
  require Logger

  alias Alerts.{Alert, Parser}
  alias Api.{Event, JsonApi}
  alias Phoenix.PubSub

  @type event_type :: :reset | :add | :update | :remove

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)

    GenStage.start_link(
      __MODULE__,
      opts,
      name: name
    )
  end

  def init(opts) do
    producer_consumer = Keyword.fetch!(opts, :subscribe_to)
    broadcast_fn = Keyword.get(opts, :broadcast_fn, &PubSub.broadcast/3)
    {:consumer, %{broadcast_fn: broadcast_fn}, subscribe_to: [producer_consumer]}
  end

  def handle_events(events, _from, state) do
    :ok = Enum.each(events, &send_event(&1, state.broadcast_fn))
    {:noreply, [], state}
  end

  defp send_event(
         %Event{
           event: :remove,
           data: %JsonApi{data: data}
         },
         broadcast_fn
       ) do
    data
    |> Enum.map(& &1.id)
    |> broadcast(:remove, broadcast_fn)
  end

  defp send_event(
         %Event{
           event: type,
           data: %JsonApi{data: data}
         },
         broadcast_fn
       ) do
    data
    |> Enum.map(&Parser.parse/1)
    |> broadcast(type, broadcast_fn)
  end

  @typep broadcast_fn :: (atom, String.t(), any -> :ok | {:error, any})
  @spec broadcast([Alert.t() | String.t()], event_type, broadcast_fn) :: :ok
  defp broadcast([], _type, _broadcast_fn), do: :ok

  defp broadcast(data, type, broadcast_fn) do
    Alerts.PubSub
    |> broadcast_fn.("alerts", {type, data})
    |> log_errors()
  end

  @spec log_errors(:ok | {:error, any}) :: :ok
  defp log_errors(:ok), do: :ok

  defp log_errors({:error, error}),
    do: Logger.error("module=#{__MODULE__} error=#{inspect(error)}")
end
