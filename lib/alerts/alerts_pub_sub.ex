defmodule Alerts.AlertsPubSub do
  @moduledoc """
  Publish alert udptaes to subscribers.
  """

  use GenServer

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
  def handle_info({:reset, alerts}, %__MODULE__{store: store} = state) do
    new_state = %__MODULE__{
      state
      | store: Store.reset(store, alerts)
    }

    broadcast(new_state)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:add, new_alerts}, %__MODULE__{store: store} = state) do
    new_state = %__MODULE__{
      state
      | store: Store.add(store, new_alerts)
    }

    broadcast(new_state)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:update, updated_alerts}, %__MODULE__{store: store} = state) do
    new_state = %__MODULE__{
      state
      | store: Store.update(store, updated_alerts)
    }

    broadcast(new_state)

    {:noreply, new_state}
  end

  def handle_info({:remove, alert_ids_to_remove}, %__MODULE__{store: store} = state) do
    new_state = %__MODULE__{
      state
      | store: Store.remove(store, alert_ids_to_remove)
    }

    broadcast(new_state)

    {:noreply, new_state}
  end

  @spec broadcast(t()) :: :ok
  defp broadcast(state) do
    registry_key = self()

    Registry.dispatch(:alerts_subscriptions_registry, registry_key, fn entries ->
      Enum.each(entries, &send_data(&1, state))
    end)
  end

  @spec send_data({pid, any()}, t()) :: broadcast_message()
  defp send_data({pid, _}, %__MODULE__{store: store}), do: send(pid, {:alerts, Store.all(store)})
end
