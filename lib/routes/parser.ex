defmodule Routes.Parser do
  @moduledoc """
  Parse JsonApi data into Route structs.
  """

  alias Api.JsonApi.Item
  alias Routes.Route

  @spec parse_route(Item.t()) :: Route.t()
  def parse_route(%Item{id: id, attributes: attributes}) do
    %Route{
      id: id,
      type: attributes["type"],
      short_name: attributes["short_name"],
      long_name: attributes["long_name"],
      color: attributes["color"],
      sort_order: attributes["sort_order"],
      direction_names: attributes["direction_names"],
      direction_destinations: attributes["direction_destinations"]
    }
  end
end
