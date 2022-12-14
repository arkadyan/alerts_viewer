defmodule AlertsViewerWeb.DateTimeHelpers do
  @doc """
  Return a human-friendly date-time string relative to "now".
  Use the time if today, the month and day if this year, and the month and
  year if a different year.

  iex> friendly_date_time(~U[2022-01-12 14:01:00.00Z], ~U[2022-01-12 15:02:00.00Z])
  "2:01 PM"
  iex> friendly_date_time(~U[2022-01-07 14:01:00.00Z], ~U[2022-01-12 15:02:00.00Z])
  "Jan 7"
  iex> friendly_date_time(~U[2021-12-07 14:01:00.00Z], ~U[2022-01-12 15:02:00.00Z])
  "Dec 2021"
  iex> friendly_date_time(nil, ~U[2022-01-12 15:02:00.00Z])
  ""
  """
  @spec friendly_date_time(DateTime.t() | nil) :: String.t()
  @spec friendly_date_time(DateTime.t() | nil, DateTime.t()) :: String.t()
  def friendly_date_time(dt, now \\ DateTime.now!("America/New_York"))
  def friendly_date_time(nil, _now), do: ""

  def friendly_date_time(dt, now) do
    format = date_time_format(dt, now)
    Calendar.strftime(dt, format)
  end

  @spec date_time_format(DateTime.t(), DateTime.t()) :: String.t()
  defp date_time_format(dt, now) when dt.day == now.day, do: "%-I:%M %p"
  defp date_time_format(dt, now) when dt.year == now.year, do: "%b %-d"
  defp date_time_format(_, _), do: "%b %Y"
end
