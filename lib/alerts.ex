defmodule Alerts do
  @moduledoc """
  Service alerts.
  """

  alias Alerts.{Alert, AlertsPubSub}

  @spec subscribe :: [Alert.t()]
  defdelegate subscribe(), to: AlertsPubSub

  @spec all :: [Alert.t()]
  defdelegate all(), to: AlertsPubSub
end
