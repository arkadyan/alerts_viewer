defmodule Routes do
  @moduledoc """
  Context for dealing with routes.
  """

  require Logger

  alias Routes.{Parser, Route}

  @doc """
  Get all bus routes
  """
  @spec all_bus_routes() :: [Route.t()]
  @spec all_bus_routes(keyword()) :: [Route.t()]
  def all_bus_routes(opts \\ []) do
    case get_all_bus_routes(opts) do
      {:ok, routes} -> routes
      {:error, _} -> []
    end
  end

  @spec get_all_bus_routes(keyword()) :: {:ok, [Route.t()]} | {:error, any}
  defp get_all_bus_routes(opts) do
    get_fn = Keyword.get(opts, :get_fn, &Api.get/2)

    "/routes"
    |> get_fn.(type: 3)
    |> handle_response()
  end

  # Parses json into a list of routes, or an error if it happened.
  @spec handle_response(Api.JsonApi.t() | {:error, any}) ::
          {:ok, [Route.t()]} | {:error, any}
  defp handle_response({:ok, %{data: data}}) do
    routes =
      data
      |> Enum.reject(&hidden?/1)
      |> Enum.map(&Parser.parse_route/1)

    {:ok, routes}
  end

  defp handle_response({:error, reason}) do
    Logger.warn(fn -> Log.line("Error getting routes from the API", error: reason) end)
    {:error, reason}
  end

  # Determines if the given route data is hidden
  @spec hidden?([Api.JsonApi.Item.t()]) :: boolean
  defp hidden?(%{id: "2427"}), do: true
  defp hidden?(%{id: "3233"}), do: true
  defp hidden?(%{id: "3738"}), do: true
  defp hidden?(%{id: "4050"}), do: true
  defp hidden?(%{id: "725"}), do: true
  defp hidden?(%{id: "8993"}), do: true
  defp hidden?(%{id: "116117"}), do: true
  defp hidden?(%{id: "214216"}), do: true
  defp hidden?(%{id: "441442"}), do: true
  defp hidden?(%{id: "9701"}), do: true
  defp hidden?(%{id: "9702"}), do: true
  defp hidden?(%{id: "9703"}), do: true
  defp hidden?(%{id: "Logan-" <> _}), do: true
  defp hidden?(%{id: "CapeFlyer"}), do: true
  defp hidden?(%{id: "Boat-F3"}), do: true
  defp hidden?(_), do: false
end
