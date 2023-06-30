defmodule TripUpdates.Supervisor do
  @moduledoc """
  Supervisor for Trip Updates application. Supports subscribing to blocked routes.
  """

  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      {Registry, keys: :duplicate, name: :trip_updates_subscriptions_registry},
      TripUpdates.TripUpdatesPubSub
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
