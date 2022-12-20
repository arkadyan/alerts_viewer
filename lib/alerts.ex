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
end
