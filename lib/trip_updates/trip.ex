defmodule TripUpdates.Trip do
  @moduledoc """
  Structure for representing a trip
  """

  defstruct [
    :direction_id,
    :route_id,
    :start_date,
    :start_time,
    :trip_id,
    :route_pattern_id,
    :schedule_relationship
  ]

  @type t :: %__MODULE__{
          direction_id: String.t() | nil,
          route_id: String.t() | nil,
          start_date: integer() | nil,
          start_time: integer() | nil,
          trip_id: String.t(),
          route_pattern_id: String.t() | nil,
          schedule_relationship: String.t() | nil
        }

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
