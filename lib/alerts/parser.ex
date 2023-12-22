defmodule Alerts.Parser do
  @moduledoc """
  Parse Json data from the API into Alert structs.
  """

  alias Alerts.Alert
  alias Api.JsonApi.Item

  @spec parse(Item.t()) :: Alert.t()
  def parse(%Item{id: id, attributes: attributes}) do
    %Alert{
      id: id,
      active_period: Enum.map(attributes["active_period"], &active_period/1),
      banner: trimmed_or_nil(attributes["banner"]),
      cause: cause(attributes["cause"]),
      created_at: parse_time(attributes["created_at"]),
      description: trimmed_or_nil(attributes["description"]),
      effect: effect(attributes["effect"]),
      header: String.trim(attributes["header"]),
      informed_entity: Enum.map(attributes["informed_entity"], &informed_entity/1),
      lifecycle: lifecycle(attributes["lifecycle"]),
      service_effect: String.trim(attributes["service_effect"]),
      severity: attributes["severity"],
      short_header: String.trim(attributes["short_header"]),
      timeframe: trimmed_or_nil(attributes["timeframe"]),
      updated_at: parse_time(attributes["updated_at"]),
      url: trimmed_or_nil(attributes["url"])
    }
  end

  @type string_or_nil :: String.t() | nil

  # Trim leading/trailing whitespace from a string, or return nil if nil or empty string
  @spec trimmed_or_nil(string_or_nil()) :: string_or_nil()
  defp trimmed_or_nil(nil), do: nil

  defp trimmed_or_nil(str) do
    case String.trim(str) do
      "" -> nil
      str -> str
    end
  end

  @spec active_period(%{String.t() => string_or_nil()}) :: Alert.datetime_pair()
  defp active_period(%{"start" => start, "end" => stop}) do
    {parse_time(start), parse_time(stop)}
  end

  @spec parse_time(string_or_nil()) :: DateTime.t() | nil
  defp parse_time(nil), do: nil

  defp parse_time(str) do
    {:ok, datetime, _} = DateTime.from_iso8601(str)
    datetime
  end

  @spec cause(String.t()) :: Alert.cause()
  defp cause("ACCIDENT"), do: :accident
  defp cause("AMTRAK"), do: :amtrak
  defp cause("AN_EARLIER_MECHANICAL_PROBLEM"), do: :an_earlier_mechanical_problem
  defp cause("AN_EARLIER_SIGNAL_PROBLEM"), do: :an_earlier_signal_problem
  defp cause("AUTOS_IMPEDING_SERVICE"), do: :autos_impeding_service
  defp cause("COAST_GUARD_RESTRICTION"), do: :coast_guard_restriction
  defp cause("CONGESTION"), do: :congestion
  defp cause("CONSTRUCTION"), do: :construction
  defp cause("CROSSING_MALFUNCTION"), do: :crossing_malfunction
  defp cause("DEMONSTRATION"), do: :demonstration
  defp cause("DISABLED_BUS"), do: :disabled_bus
  defp cause("DISABLED_TRAIN"), do: :disabled_train
  defp cause("DRAWBRIDGE_BEING_RAISED"), do: :drawbridge_being_raised
  defp cause("ELECTRICAL_WORK"), do: :electrical_work
  defp cause("FIRE"), do: :fire
  defp cause("FOG"), do: :fog
  defp cause("FREIGHT_TRAIN_INTERFERENCE"), do: :freight_train_interference
  defp cause("HAZMAT_CONDITION"), do: :hazmat_condition
  defp cause("HEAVY_RIDERSHIP"), do: :heavy_ridership
  defp cause("HIGH_WINDS"), do: :high_winds
  defp cause("HOLIDAY"), do: :holiday
  defp cause("HURRICANE"), do: :hurricane
  defp cause("ICE_IN_HARBOR"), do: :ice_in_harbor
  defp cause("MAINTENANCE"), do: :maintenance
  defp cause("MECHANICAL_PROBLEM"), do: :mechanical_problem
  defp cause("MEDICAL_EMERGENCY"), do: :medical_emergency
  defp cause("PARADE"), do: :parade
  defp cause("POLICE_ACTION"), do: :police_action
  defp cause("POLICE_ACTIVITY"), do: :police_activity
  defp cause("POWER_PROBLEM"), do: :power_problem
  defp cause("SEVERE_WEATHER"), do: :severe_weather
  defp cause("SIGNAL_ISSUE"), do: :signal_issue
  defp cause("SIGNAL_PROBLEM"), do: :signal_problem
  defp cause("SLIPPERY_RAIL"), do: :slippery_rail
  defp cause("SNOW"), do: :snow
  defp cause("SPECIAL_EVENT"), do: :special_event
  defp cause("SPEED_RESTRICTION"), do: :speed_restriction
  defp cause("STRIKE"), do: :strike
  defp cause("SWITCH_ISSUE"), do: :switch_problem
  defp cause("SWITCH_PROBLEM"), do: :switch_problem
  defp cause("TECHNICAL_PROBLEM"), do: :technical_problem
  defp cause("TIE_REPLACEMENT"), do: :tie_replacement
  defp cause("TRACK_PROBLEM"), do: :track_problem
  defp cause("TRACK_WORK"), do: :track_work
  defp cause("TRAFFIC"), do: :traffic
  defp cause("UNKNOWN_CAUSE"), do: :unknown_cause
  defp cause("UNRULY_PASSENGER"), do: :unruly_passenger
  defp cause("WEATHER"), do: :weather
  defp cause(_), do: :other_cause

  @spec effect(String.t()) :: Alert.effect()
  defp effect("ACCESS_ISSUE"), do: :access_issue
  defp effect("ADDITIONAL_SERVICE"), do: :additional_service
  defp effect("AMBER_ALERT"), do: :amber_alert
  defp effect("BIKE_ISSUE"), do: :bike_issue
  defp effect("CANCELLATION"), do: :cancellation
  defp effect("DELAY"), do: :delay
  defp effect("DETOUR"), do: :detour
  defp effect("DOCK_CLOSURE"), do: :dock_closure
  defp effect("DOCK_ISSUE"), do: :dock_issue
  defp effect("ELEVATOR_CLOSURE"), do: :elevator_closure
  defp effect("ESCALATOR_CLOSURE"), do: :escalator_closure
  defp effect("EXTRA_SERVICE"), do: :extra_service
  defp effect("FACILITY_ISSUE"), do: :facility_issue
  defp effect("MODIFIED_SERVICE"), do: :modified_service
  defp effect("NO_SERVICE"), do: :no_service
  defp effect("OTHER_EFFECT"), do: :other_effect
  defp effect("PARKING_CLOSURE"), do: :parking_closure
  defp effect("PARKING_ISSUE"), do: :parking_issue
  defp effect("POLICY_CHANGE"), do: :policy_change
  defp effect("SCHEDULE_CHANGE"), do: :schedule_change
  defp effect("SERVICE_CHANGE"), do: :service_change
  defp effect("SHUTTLE"), do: :shuttle
  defp effect("SNOW_ROUTE"), do: :snow_route
  defp effect("STATION_CLOSURE"), do: :station_closure
  defp effect("STATION_ISSUE"), do: :station_issue
  defp effect("STOP_CLOSURE"), do: :stop_closure
  defp effect("STOP_MOVE"), do: :stop_move
  defp effect("STOP_MOVED"), do: :stop_moved
  defp effect("SUMMARY"), do: :summary
  defp effect("SUSPENSION"), do: :suspension
  defp effect("TRACK_CHANGE"), do: :track_change
  defp effect("UNKNOWN_EFFECT"), do: :unknown_effect

  @spec lifecycle(String.t()) :: Alert.lifecycle()
  defp lifecycle("NEW"), do: :new
  defp lifecycle("ONGOING"), do: :ongoing
  defp lifecycle("ONGOING_UPCOMING"), do: :ongoing_upcoming
  defp lifecycle("UPCOMING"), do: :upcoming

  @type informed_entity_data :: %{String.t() => any()}
  @spec informed_entity(informed_entity_data()) :: Alert.informed_entity()
  defp informed_entity(data) do
    %{
      activities: Enum.map(data["activities"], &activity/1),
      direction_id: data["direction_id"],
      facility: data["facility"],
      route: data["route"],
      route_type: data["route_type"],
      stop: data["stop"],
      trip: data["trip"]
    }
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end

  @spec activity(String.t()) :: Alert.activity()
  defp activity("BOARD"), do: :board
  defp activity("BRINGING_BIKE"), do: :bringing_bike
  defp activity("EXIT"), do: :exit
  defp activity("PARK_CAR"), do: :park_car
  defp activity("RIDE"), do: :ride
  defp activity("STORE_BIKE"), do: :store_bike
  defp activity("USING_ESCALATOR"), do: :using_escalator
  defp activity("USING_WHEELCHAIR"), do: :using_wheelchair
end
