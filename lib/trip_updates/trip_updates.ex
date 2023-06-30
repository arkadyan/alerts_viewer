defmodule TripUpdates.TripUpdates do
  @moduledoc """
  Consumes output from the Trip Updates GTFS feed and reports them to the realtime server.
  """
  use GenStage

  alias TripUpdates.{StopTimeUpdate, TripUpdatesPubSub}
  @type t :: %{String.t() => [StopTimeUpdate.t()]}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    {:consumer, :the_state_does_not_matter, opts}
  end

  # If we get a reply after we've already timed out, ignore it
  @impl GenStage
  def handle_info({reference, _}, state) when is_reference(reference),
    do: {:noreply, [], state}

  @impl GenStage
  def handle_events(events, _from, state) do
    events
    |> List.last()
    |> TripUpdatesPubSub.update_block_waivered_routes()

    {:noreply, [], state}
  end
end
