defmodule Log do
  @moduledoc """
  Utility functions for generating log lines.
  """

  @doc """
  Generate a log line from a message and a keyword list.
  Farmat each keyword like: "key=value".

  iex> Log.line("Test message", [one: "apple", two: 123])
  "Test message one=apple two=123"
  """
  @spec line(String.t(), keyword()) :: String.t()
  def line(message, data) do
    [
      message
      | Enum.map(data, &key_value_string/1)
    ]
    |> Enum.join(" ")
  end

  defp key_value_string({key, value}), do: "#{key}=#{value}"
end
