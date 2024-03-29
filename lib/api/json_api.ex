defmodule Api.JsonApi.Item do
  @moduledoc """
  A data structure for JSON data items.
  """

  defstruct [:type, :id, :attributes, :relationships]

  @type t :: %__MODULE__{
          type: String.t(),
          id: String.t(),
          attributes: %{String.t() => any},
          relationships: %{String.t() => list(__MODULE__.t())}
        }
end

defmodule Api.JsonApi.Error do
  @moduledoc """
  A data structure for JSON error items.
  """

  defstruct [:code, :source, :detail, :meta]

  @type t :: %__MODULE__{
          code: String.t() | nil,
          source: String.t() | nil,
          detail: String.t() | nil,
          meta: %{String.t() => any}
        }
end

defmodule Api.JsonApi do
  @moduledoc """
  Model and parse JSON data from the API.
  """

  alias Api.JsonApi.{Error, Item}

  defstruct data: []

  @type t :: %__MODULE__{
          data: list(Item.t())
        }

  @spec empty() :: t()
  def empty do
    %__MODULE__{
      data: []
    }
  end

  @spec merge(t(), t()) :: t()
  def merge(j1, j2) do
    %__MODULE__{
      data: j1.data ++ j2.data
    }
  end

  @spec parse(String.t()) :: {:ok, t()} | {:error, any}
  def parse(body) do
    with {:ok, parsed} <- Jason.decode(body),
         {:ok, data} <- parse_data(parsed) do
      {:ok, %__MODULE__{data: data}}
    else
      {:error, [_ | _] = errors} ->
        {:error, parse_errors(errors)}

      error ->
        error
    end
  end

  @spec parse_data(term()) :: {:ok, [Item.t()]} | {:error, any}
  defp parse_data(%{"data" => data} = parsed) when is_list(data) do
    included = parse_included(parsed)
    {:ok, Enum.map(data, &parse_data_item(&1, included))}
  end

  defp parse_data(%{"data" => data} = parsed) do
    included = parse_included(parsed)
    {:ok, [parse_data_item(data, included)]}
  end

  defp parse_data(%{"errors" => errors}) do
    {:error, errors}
  end

  defp parse_data(data) when is_list(data) do
    # V3Api.Stream receives :reset data as a list of items
    parse_data(%{"data" => data})
  end

  defp parse_data(%{"id" => _} = data) do
    # V3Api.Stream receives :add, :update, and :remove data as single items
    parse_data(%{"data" => data})
  end

  defp parse_data(%{}) do
    {:error, :invalid}
  end

  @spec parse_data_item(map(), map()) :: Item.t()
  defp parse_data_item(%{"type" => type, "id" => id, "attributes" => attributes} = item, included) do
    %Item{
      type: type,
      id: id,
      attributes: attributes,
      relationships: load_relationships(item["relationships"], included)
    }
  end

  defp parse_data_item(%{"type" => type, "id" => id}, _) do
    %Item{
      type: type,
      id: id
    }
  end

  @spec load_relationships(map() | nil, map()) :: map()
  defp load_relationships(nil, _) do
    %{}
  end

  defp load_relationships(%{} = relationships, included) do
    Map.new(relationships, fn {key, value} ->
      {key, load_single_relationship(value, included)}
    end)
  end

  @spec load_single_relationship(any, map()) :: list()
  defp load_single_relationship(relationship, _) when relationship == %{} do
    []
  end

  defp load_single_relationship(%{"data" => data}, included) when is_list(data) do
    data
    |> Enum.map(&match_included(&1, included))
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&parse_data_item(&1, included))
  end

  defp load_single_relationship(%{"data" => %{} = data}, included) do
    case data |> match_included(included) do
      nil -> []
      item -> [parse_data_item(item, included)]
    end
  end

  defp load_single_relationship(_, _) do
    []
  end

  @spec match_included(map() | nil, map()) :: any()
  defp match_included(nil, _) do
    nil
  end

  defp match_included(%{"type" => type, "id" => id} = item, included) do
    Map.get(included, {type, id}, item)
  end

  @spec parse_included(term()) :: map()
  defp parse_included(params) do
    included = Map.get(params, "included", [])

    data =
      case Map.get(params, "data") do
        nil -> []
        list when is_list(list) -> list
        item -> [item]
      end

    data = Enum.map(data, fn item -> Map.delete(item, "relationships") end)

    included
    |> Enum.concat(data)
    |> Map.new(fn %{"type" => type, "id" => id} = item ->
      {{type, id}, item}
    end)
  end

  @spec parse_errors(list()) :: [Error.t()]
  defp parse_errors(errors), do: Enum.map(errors, &parse_error/1)

  @spec parse_error(any()) :: Error.t()
  defp parse_error(error) do
    %Error{
      code: error["code"],
      detail: error["detail"],
      source: error["source"],
      meta: error["meta"] || %{}
    }
  end
end
