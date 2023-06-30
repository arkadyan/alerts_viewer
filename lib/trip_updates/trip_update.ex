defmodule TripUpdates.TripUpdate do
  @moduledoc """
  TripUpdate represents a (potential) change to a GTFS trip.
  """

  alias TripUpdates.{StopTimeUpdate, Trip}

  defstruct [
    :overload_offset,
    :start_date,
    :start_time,
    :trip,
    :stop_time_update,
    :timestamp
  ]

  @type t :: %__MODULE__{
          start_date: integer() | nil,
          start_time: integer() | nil,
          trip: Trip.t(),
          stop_time_update: [StopTimeUpdate.t()],
          timestamp: integer() | nil
        }

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
