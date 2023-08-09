defmodule Routes.Route do
  @moduledoc """
  Describes an individual route.
  """

  defstruct [
    :id,
    :type,
    :short_name,
    :long_name,
    :color,
    :sort_order,
    :direction_names,
    :direction_destinations
  ]

  @type id :: String.t()

  # 0	Light Rail
  # 1	Heavy Rail
  # 2	Commuter Rail
  # 3	Bus
  # 4	Ferry
  @type route_type :: 0..4

  @type direction_name :: String.t()
  @type direction_destination :: String.t()

  @type t :: %__MODULE__{
          id: id(),
          type: route_type(),
          short_name: String.t(),
          long_name: String.t(),
          color: String.t(),
          sort_order: non_neg_integer(),
          direction_names: [direction_name()],
          direction_destinations: [direction_destination()]
        }

  @doc """
  Returns the name for this route. Defaults to using the short name, but falls back to the long name.
  Returns id if no name is present, or empty string if we have nothing (unlikely but not enforced).

  iex> Route.name(%Route{id: "1", type: 3, short_name: "short", long_name: "long"})
  "short"
  iex> Route.name(%Route{id: "1", type: 3, long_name: "long"})
  "long"
  iex> Route.name(%Route{id: "1"})
  "1"
  iex> Route.name(%Route{type: 3})
  ""
  """
  @spec name(t()) :: String.t()
  def name(%__MODULE__{short_name: short_name}) when short_name != nil and short_name != "",
    do: short_name

  def name(%__MODULE__{long_name: long_name}) when long_name != nil and long_name != "",
    do: long_name

  def name(%__MODULE__{id: route_id}) when route_id != nil, do: route_id
  def name(%__MODULE__{}), do: ""
end
