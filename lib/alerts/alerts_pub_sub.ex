defmodule Alerts.AlertsPubSub do
  @moduledoc """
  Publish alert updates to subscribers.
  """

  use GenServer

  require Logger
  alias Alerts.{Alert, Store}

  @enforce_keys [:store]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          store: Store.t()
        }

  @type broadcast_message :: {:alerts, [Alert.t()]}

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

  @spec subscribe() :: [Alert.t()]
  @spec subscribe(GenServer.server()) :: [Alert.t()]
  def subscribe(server \\ __MODULE__) do
    {registry_key, alerts} = GenServer.call(server, {:subscribe})
    Registry.register(:alerts_subscriptions_registry, registry_key, :value_does_not_matter)
    alerts
  end

  @spec all() :: [Alert.t()]
  @spec all(GenServer.server()) :: [Alert.t()]
  def all(server \\ __MODULE__), do: GenServer.call(server, {:all})

  @spec get(Alert.id()) :: {:ok, Alert.t()} | :not_found
  @spec get(Alert.id(), GenServer.server()) :: {:ok, Alert.t()} | :not_found
  def get(id, server \\ __MODULE__), do: GenServer.call(server, {:get, id})

  # Server

  @impl GenServer
  def init(opts) do
    subscribe_fn = Keyword.get(opts, :subscribe_fn, &Phoenix.PubSub.subscribe/2)
    subscribe_fn.(Alerts.PubSub, "alerts")

    {:ok, %__MODULE__{store: Store.init()}}
  end

  @impl GenServer
  def handle_call({:subscribe}, _from, %__MODULE__{store: store} = state) do
    registry_key = self()
    {:reply, {registry_key, Store.all(store)}, state}
  end

  @impl GenServer
  def handle_call({:all}, _from, %__MODULE__{store: store} = state) do
    {:reply, Store.all(store), state}
  end

  @impl GenServer
  def handle_call({:get, id}, _from, %__MODULE__{store: store} = state) do
    {:reply, Store.by_id(store, id), state}
  end

  @impl GenServer
  def handle_info({:reset, alerts}, %__MODULE__{store: store} = state) do
    store = Store.reset(store, alerts)

    state = %__MODULE__{
      state
      | store: store
    }

    broadcast(store)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:add, new_alerts}, %__MODULE__{store: store} = state) do
    store = Store.add(store, new_alerts)

    state = %__MODULE__{
      state
      | store: store
    }

    broadcast(store)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:update, updated_alerts}, %__MODULE__{store: store} = state) do
    store = Store.update(store, updated_alerts)

    state = %__MODULE__{
      state
      | store: store
    }

    broadcast(store)

    {:noreply, state}
  end

  def handle_info({:remove, alert_ids_to_remove}, %__MODULE__{store: store} = state) do
    store = Store.remove(store, alert_ids_to_remove)

    state = %__MODULE__{
      state
      | store: store
    }

    broadcast(store)

    {:noreply, state}
  end

  @spec broadcast(Store.t()) :: :ok
  defp broadcast(store) do
    registry_key = self()

    alerts = Store.all(store)

    Logger.info(
      "Stored alerts count=#{length(alerts)} min_age=#{min_age(alerts)} median_age=#{median_age(alerts)} max_age=#{max_age(alerts)}"
    )

    Registry.dispatch(:alerts_subscriptions_registry, registry_key, fn entries ->
      Enum.each(entries, &send_data(&1, alerts))
    end)
  end

  @spec send_data({pid(), any()}, [Alert.t()]) :: broadcast_message()
  defp send_data({pid, _}, alerts), do: send(pid, {:alerts, alerts})

  @spec min_age([Alert.t()]) :: integer()
  defp min_age(alerts) do
    alerts
    |> Enum.map(&Alert.alert_duration/1)
    |> Enum.min()
  end

  @spec median_age([Alert.t()]) :: number()
  defp median_age(alerts) do
    alerts
    |> Enum.map(&Alert.alert_duration/1)
    |> Statistics.median()
  end

  @spec max_age([Alert.t()]) :: integer()
  defp max_age(alerts) do
    alerts
    |> Enum.map(&Alert.alert_duration/1)
    |> Enum.max()
  end
end
