defmodule Alerts.Store do
  @moduledoc """
  Manage a collection of alerts referenced by ID.
  """

  alias Alerts.Alert

  @enforce_keys [:ets]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          ets: :ets.tid()
        }

  def init do
    %__MODULE__{
      ets: :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])
    }
  end

  @spec all(t()) :: [Alert.t()]
  def all(%__MODULE__{ets: ets}) do
    ets
    |> :ets.tab2list()
    |> Enum.map(&elem(&1, 1))
  end

  @spec by_id(t(), Alert.id()) :: {:ok, Alert.t()} | :not_found
  def by_id(%__MODULE__{ets: ets}, id) do
    try do
      alert = :ets.lookup_element(ets, id, 2)
      {:ok, alert}
    rescue
      ArgumentError ->
        :not_found
    end
  end

  @spec reset(t(), [Alert.t()]) :: t()
  def reset(%__MODULE__{ets: ets} = store, alerts) do
    :ets.delete_all_objects(ets)
    insert_alerts(ets, alerts)
    store
  end

  @spec add(t(), [Alert.t()]) :: t()
  def add(%__MODULE__{ets: ets} = store, alerts) do
    insert_alerts(ets, alerts)
    store
  end

  @spec update(t(), [Alert.t()]) :: t()
  def update(%__MODULE__{ets: ets} = store, alerts) do
    insert_alerts(ets, alerts)
    store
  end

  @spec remove(t(), [Alert.id()]) :: t()
  def remove(%__MODULE__{ets: ets} = store, alert_ids) do
    Enum.each(alert_ids, &:ets.delete(ets, &1))
    store
  end

  @spec insert_alerts(:ets.tid(), [Alert.t()]) :: :ok
  defp insert_alerts(ets, alerts), do: Enum.each(alerts, &insert_alert(ets, &1))

  @spec insert_alert(:ets.tid(), Alert.t()) :: true
  defp insert_alert(ets, %Alert{id: id} = alert), do: :ets.insert(ets, {id, alert})
end
