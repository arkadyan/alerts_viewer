defmodule Api do
  @moduledoc """
  Interact with the MBTA V3 API.
  """

  require Logger

  alias Api.{Cache, JsonApi}

  @spec get(String.t()) :: {:ok, JsonApi.t()} | {:error, any}
  @spec get(String.t(), Keyword.t()) :: {:ok, JsonApi.t()} | {:error, any}
  @spec get(String.t(), Keyword.t(), Keyword.t()) :: {:ok, JsonApi.t()} | {:error, any}
  def get(path, params \\ [], opts \\ []) do
    Logger.debug(fn ->
      Log.line(
        "API.get",
        path: inspect(path),
        params: inspect(params)
      )
    end)

    opts = Keyword.merge(default_options(), opts)

    with {time, response} <- timed_get(path, params, opts),
         :ok <- log_response(path, params, time, response),
         {:ok, http_response} <- response,
         {:ok, http_response} <- Cache.cache_response(path, params, http_response),
         {:ok, body} <- body(http_response),
         {:ok, parsed_json} <- JsonApi.parse(body) do
      {:ok, parsed_json}
    else
      {:error, :no_cached_response} ->
        log_response_error(path, params, "no cached response")
        {:error, :no_cached_response}

      {:error, error} ->
        log_response_error(path, params, error)
        {:error, error}

      error ->
        log_response_error(path, params, error)
        {:error, error}
    end
  end

  def body(%{headers: headers, body: body}) do
    case Enum.find(
           headers,
           &(String.downcase(elem(&1, 0)) == "content-encoding")
         ) do
      {_, "gzip"} ->
        {:ok, :zlib.gunzip(body)}

      _ ->
        {:ok, body}
    end
  rescue
    e in ErlangError -> {:error, e.original}
  end

  def body(other) do
    other
  end

  defp default_options do
    [
      base_url: Application.get_env(:alerts_viewer, :api_url),
      api_key: Application.get_env(:alerts_viewer, :api_key),
      timeout: 5_000
    ]
  end

  defp timed_get(path, params, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    api_key = Keyword.fetch!(opts, :api_key)
    timeout = Keyword.fetch!(opts, :timeout)

    url = base_url <> path
    headers = [{"x-api-key", api_key}]

    {time, response} =
      :timer.tc(fn -> HTTPoison.get(url, headers, params: params, recv_timeout: timeout) end)

    {time, response}
  end

  @spec log_response(String.t(), Keyword.t(), integer, any) :: :ok
  defp log_response(path, params, time, response) do
    Logger.debug(fn ->
      Log.line(
        "Api.get response",
        [path: inspect(path), params: inspect(params)] ++
          log_body(response) ++
          [duration: time / 1_000, request_id: Logger.metadata() |> Keyword.get(:request_id)]
      )
    end)
  end

  defp log_body({:ok, response}),
    do: [status: response.status_code, content_length: byte_size(response.body)]

  defp log_body({:error, error}), do: [status: "error", error: inspect(error)]

  @spec log_response_error(String.t(), Keyword.t(), String.t()) :: :ok
  defp log_response_error(path, params, error) do
    Logger.debug(fn ->
      Log.line(
        "Api.get response error",
        path: inspect(path),
        params: inspect(params),
        error: inspect(error)
      )
    end)
  end
end
