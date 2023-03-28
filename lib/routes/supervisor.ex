defmodule Routes.Supervisor do
  @moduledoc """
  Supervisor for the Routes application. Supports subscribing to route stats.
  """

  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      {Registry, keys: :duplicate, name: :route_stats_subscriptions_registry},
      Routes.RouteStatsPubSub
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
