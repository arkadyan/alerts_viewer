defmodule AlertsViewerWeb.StringHelpers do
  @moduledoc """
  Utility functions for formatting strings and atoms.
  """

  @doc """
  Return a human-friendly string for an atom.

  iex> humanized_atom(:delay)
  "Delay"
  iex> humanized_atom(:service_change)
  "Service Change"
  """
  @spec humanized_atom(atom) :: String.t()
  def humanized_atom(effect_atom) do
    effect_atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
