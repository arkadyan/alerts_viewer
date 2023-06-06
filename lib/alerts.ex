defmodule Alerts do
  @moduledoc """
  Service alerts.
  """

  alias Alerts.{Alert, AlertsPubSub}

  @spec subscribe :: [Alert.t()]
  defdelegate subscribe(), to: AlertsPubSub

  @spec all :: [Alert.t()]
  defdelegate all(), to: AlertsPubSub

  @spec get(Alert.id()) :: {:ok, Alert.t()} | :not_found
  defdelegate get(id), to: AlertsPubSub

  @doc """
  Filter a list of alerts by effect type.
  """
  @spec by_effect([Alert.t()], String.t()) :: [Alert.t()]
  def by_effect(alerts, ""), do: alerts

  def by_effect(alerts, effect) do
    effect_atom = String.to_atom(effect)
    Enum.filter(alerts, &(&1.effect == effect_atom))
  end

  @doc """
  Filter a list of alerts by service type.
  """
  @spec by_service([Alert.t()], String.t()) :: [Alert.t()]
  def by_service(alerts, ""), do: alerts

  def by_service(alerts, "access"),
    do: Enum.filter(alerts, &Alert.matches_service_type(&1, :access))

  def by_service(alerts, route_type_string),
    do: Enum.filter(alerts, &Alert.matches_service_type(&1, String.to_integer(route_type_string)))

  @doc """
  Return a map with route ids as string keys and a list of alerts as the value
  """
  @spec by_route([Alert.t()]) :: map()
  def by_route(alerts) do
    alerts
    |> Enum.filter(&Enum.any?(&1.informed_entity, fn ie -> !is_nil(ie.route) end))
    |> Enum.reduce(%{}, fn alert, acc ->
      routes = Enum.map(alert.informed_entity, & &1.route)

      alert_by_route_id =
        Enum.reduce(routes, %{}, fn route_id, route_ids_acc ->
          Map.merge(route_ids_acc, %{
            route_id => [alert]
          })
        end)

      Map.merge(alert_by_route_id, acc, fn _k, route_ids_map, acc ->
        route_ids_map ++ acc
      end)
    end)
  end

  @doc """
  Search for alerts based on ID, header, or description field content
  """
  @fields_to_search_on [:id, :header, :description]
  @spec search([Alert.t()], String.t()) :: [Alert.t()]
  def search(alerts, search) do
    lowercase_search = String.downcase(search)

    Enum.filter(alerts, fn alert ->
      Enum.any?(@fields_to_search_on, fn field ->
        alert
        |> string_value(field)
        |> String.downcase()
        |> String.contains?(lowercase_search)
      end)
    end)
  end

  @spec string_value(map(), atom()) :: String.t()
  defp string_value(map, key) do
    case Map.get(map, key) do
      nil ->
        ""

      str ->
        str
    end
  end
end
