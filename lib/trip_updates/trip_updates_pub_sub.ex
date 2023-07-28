defmodule TripUpdates.TripUpdatesPubSub do
  @moduledoc """
  Publish a list of blocked routes to subscribers.
  """
  use GenServer
  alias TripUpdates.{StopTimeUpdate, TripUpdate, TripUpdates}

  defstruct block_waivered_routes: []

  @type t :: %__MODULE__{
          block_waivered_routes: [String.t()]
        }

  # Client

  @spec start_link() :: GenServer.on_start()
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(
      __MODULE__,
      opts,
      name: name
    )
  end

  @spec subscribe() :: [TripUpdate.t()]
  @spec subscribe(GenServer.server()) :: [TripUpdate.t()]
  def subscribe(server \\ __MODULE__) do
    {registry_key, block_waivered_routes} = GenServer.call(server, :subscribe)
    Registry.register(:trip_updates_subscriptions_registry, registry_key, :value_does_not_matter)
    block_waivered_routes
  end

  def all(server \\ __MODULE__), do: GenServer.call(server, :all)

  @spec update_block_waivered_routes(
          [TripUpdates.t()],
          atom | pid | {atom, any} | {:via, atom, any}
        ) :: :ok
  def update_block_waivered_routes(trip_updates, server \\ __MODULE__) do
    # puts into state a list of routes which have gotten a trip update
    # where all the stop updates have a cancellation reason

    block_waivered_routes =
      trip_updates
      |> Enum.filter(&(are_all_cancelled?(&1) and is_it_fresh?(&1)))
      |> Enum.group_by(& &1.trip.route_id)
      |> Map.keys()

    GenServer.cast(server, {:update_block_waivered_routes, block_waivered_routes})
  end

  # Server

  @impl GenServer
  def init(_opts) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call(
        :subscribe,
        _from,
        %__MODULE__{block_waivered_routes: block_waivered_routes} = state
      ) do
    registry_key = self()
    {:reply, {registry_key, block_waivered_routes}, state}
  end

  @impl GenServer
  def handle_call(:all, _from, %__MODULE__{block_waivered_routes: block_waivered_routes} = state) do
    {:reply, block_waivered_routes, state}
  end

  @impl GenServer
  def handle_cast(
        {:update_block_waivered_routes, block_waivered_routes},
        %__MODULE__{} = state
      ) do
    new_state = %__MODULE__{
      state
      | block_waivered_routes: block_waivered_routes
    }

    :ok = broadcast(new_state)

    {:noreply, new_state}
  end

  defp broadcast(%__MODULE__{block_waivered_routes: block_waivered_routes}) do
    registry_key = self()

    Registry.dispatch(:trip_updates_subscriptions_registry, registry_key, fn entries ->
      Enum.each(entries, &send_data(&1, block_waivered_routes))
    end)
  end

  defp send_data({pid, _}, block_waivered_routes),
    do: send(pid, {:block_waivered_routes, block_waivered_routes})

  defp are_all_cancelled?(trip_update) do
    Enum.all?(trip_update.stop_time_update, fn update ->
      StopTimeUpdate.is_block_waiver?(update)
    end)
  end

  def is_it_fresh?(trip_update, current_time \\ DateTime.now!("America/New_York")) do
    # returns true if most recent arrival time in a stop update is in the future
    last_stop_arrival(trip_update) >= current_time
  end

  defp last_stop_arrival(trip_update) do
    trip_update.stop_time_update |> Enum.map(& &1.arrival_time) |> Enum.max(DateTime)
  end
end
