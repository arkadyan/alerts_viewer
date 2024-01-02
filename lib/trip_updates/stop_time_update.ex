defmodule TripUpdates.StopTimeUpdate do
  @moduledoc """
  Structure for representing an update to a StopTime (e.g. a predicted arrival or departure)
  """

  # The full mapping between "cause_description" and "cause_id":
  # B - Manpower	      23
  # C - No Equipment	  24
  # D - Disabled Bus	  25
  # E - Diverted	      26
  # F - Traffic	        27
  # G - Accident	      28
  # H - Weather	        29
  # I - Operator Error	30
  # J - Other	          1
  # K - Adjusted	      31
  # L - Shuttle	        32
  # T - Inactive TM	    33

  defstruct [
    :arrival_time,
    :departure_time,
    :uncertainty,
    :stop_id,
    :stop_sequence,
    :cause_description,
    :cause_id,
    :remark,
    :schedule_relationship,
    :status
  ]

  @type t :: %__MODULE__{
          arrival_time: integer() | nil,
          departure_time: integer() | nil,
          uncertainty: integer() | nil,
          stop_id: integer() | nil,
          stop_sequence: integer() | nil,
          cause_description: String.t() | nil,
          cause_id: String.t() | nil,
          remark: String.t() | nil,
          schedule_relationship: String.t() | nil,
          status: String.t() | nil
        }

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
