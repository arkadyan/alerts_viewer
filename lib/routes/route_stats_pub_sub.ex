defmodule Routes.RouteStatsPubSub do
  @moduledoc """
  Publish route updates to subscribers.
  """

  use GenServer

  alias Routes.{Route, RouteStats}
  alias Vehicles.Vehicle

  defstruct stats_by_route: %{}

  @type vehicles_by_route() :: %{Route.id() => [Vehicle.t()]}

  @type t :: %__MODULE__{
          stats_by_route: RouteStats.stats_by_route()
        }

  @type broadcast_message :: {:stats_by_route, RouteStats.stats_by_route()}

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

  @spec subscribe() :: RouteStats.stats_by_route()
  @spec subscribe(GenServer.server()) :: RouteStats.stats_by_route()
  def subscribe(server \\ __MODULE__) do
    {registry_key, stats_by_route} = GenServer.call(server, :subscribe)
    Registry.register(:route_stats_subscriptions_registry, registry_key, :value_does_not_matter)
    stats_by_route
  end

  @spec all() :: RouteStats.stats_by_route()
  @spec all(GenServer.server()) :: RouteStats.stats_by_route()
  def all(server \\ __MODULE__), do: GenServer.call(server, :all)

  @spec update_stats(vehicles_by_route()) :: :ok
  @spec update_stats(vehicles_by_route(), GenServer.server()) :: :ok
  def update_stats(vehicles_by_route, server \\ __MODULE__) do
    GenServer.cast(server, {:update_stats, vehicles_by_route})
  end

  # Server

  @impl GenServer
  def init(_opts) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call(:subscribe, _from, %__MODULE__{stats_by_route: stats_by_route} = state) do
    registry_key = self()
    {:reply, {registry_key, stats_by_route}, state}
  end

  @impl GenServer
  def handle_call(:all, _from, %__MODULE__{stats_by_route: stats_by_route} = state) do
    {:reply, stats_by_route, state}
  end

  @impl GenServer
  def handle_cast(
        {:update_stats, vehicles_by_route},
        %__MODULE__{} = state
      ) do
    stats_by_route =
      Map.new(vehicles_by_route, fn {route_id, vehicles} ->
        {route_id, RouteStats.from_vehicles(route_id, vehicles)}
      end)

    new_state = %__MODULE__{
      state
      | stats_by_route: stats_by_route
    }

    :ok = broadcast(new_state)

    {:noreply, new_state}
  end

  @spec broadcast(t()) :: :ok
  defp broadcast(%__MODULE__{stats_by_route: stats_by_route}) do
    registry_key = self()

    Registry.dispatch(:route_stats_subscriptions_registry, registry_key, fn entries ->
      Enum.each(entries, &send_data(&1, stats_by_route))
    end)
  end

  @spec send_data({pid(), any()}, RouteStats.stats_by_route()) :: broadcast_message()
  defp send_data({pid, _}, stats_by_route), do: send(pid, {:stats_by_route, stats_by_route})
end
