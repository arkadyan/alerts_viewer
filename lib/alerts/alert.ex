defmodule Alerts.Alert do
  @moduledoc """
  Representation of a service alert received from the MBTA API /alerts endpoint.
  """

  defstruct [
    :id,
    :active_period,
    :banner,
    :cause,
    :created_at,
    :description,
    :effect,
    :header,
    :informed_entity,
    :lifecycle,
    :service_effect,
    :severity,
    :short_header,
    :timeframe,
    :updated_at,
    :url
  ]

  @type id :: String.t()

  @type cause ::
          :accident
          | :amtrak
          | :an_earlier_mechanical_problem
          | :an_earlier_signal_problem
          | :autos_impeding_service
          | :coast_guard_restriction
          | :congestion
          | :construction
          | :crossing_malfunction
          | :demonstration
          | :disabled_bus
          | :disabled_train
          | :drawbridge_being_raised
          | :electrical_work
          | :fire
          | :fog
          | :freight_train_interference
          | :hazmat_condition
          | :heavy_ridership
          | :high_winds
          | :holiday
          | :hurricane
          | :ice_in_harbor
          | :maintenance
          | :mechanical_problem
          | :medical_emergency
          | :other_cause
          | :parade
          | :police_action
          | :police_activity
          | :power_problem
          | :severe_weather
          | :signal_issue
          | :signal_problem
          | :slippery_rail
          | :snow
          | :special_event
          | :speed_restriction
          | :strike
          | :switch_problem
          | :technical_problem
          | :tie_replacement
          | :track_problem
          | :track_work
          | :traffic
          | :unknown_cause
          | :unruly_passenger
          | :weather

  @typedoc """
  Time when the alert should be shown to the user. If missing, the alert will be shown as long as it appears in the
  feed. If multiple ranges are given, the alert will be shown during all of them.

  * `{DateTime.t, DateTime.t}` - a bound interval
  * `{DateTime.t, nil}` - an interval that started in the past and has not ended yet and is not planned to end anytime
  * `{nil, DateTime.t}` an interval that has existed for all time until the end time.

  See [GTFS Realtime `FeedMessage` `FeedEntity` `Alert` `TimeRange`](https://github.com/google/transit/blob/master/gtfs-realtime/spec/en/reference.md#message-timerange)
  """
  @type datetime_pair :: {DateTime.t(), DateTime.t()} | {DateTime.t(), nil} | {nil, DateTime.t()}

  @type effect ::
          :access_issue
          | :additional_service
          | :amber_alert
          | :bike_issue
          | :cancellation
          | :delay
          | :detour
          | :dock_closure
          | :dock_issue
          | :elevator_closure
          | :escalator_closure
          | :extra_service
          | :facility_issue
          | :modified_service
          | :no_service
          | :other_effect
          | :parking_closure
          | :parking_issue
          | :policy_change
          | :schedule_change
          | :service_change
          | :shuttle
          | :snow_route
          | :station_closure
          | :station_issue
          | :stop_closure
          | :stop_move
          | :stop_moved
          | :summary
          | :suspension
          | :track_change
          | :unknown_effect
  @effects [
    :access_issue,
    :additional_service,
    :amber_alert,
    :bike_issue,
    :cancellation,
    :delay,
    :detour,
    :dock_closure,
    :dock_issue,
    :elevator_closure,
    :escalator_closure,
    :extra_service,
    :facility_issue,
    :modified_service,
    :no_service,
    :other_effect,
    :parking_closure,
    :parking_issue,
    :policy_change,
    :schedule_change,
    :service_change,
    :shuttle,
    :snow_route,
    :station_closure,
    :station_issue,
    :stop_closure,
    :stop_move,
    :stop_moved,
    :summary,
    :suspension,
    :track_change,
    :unknown_effect
  ]

  @type activity ::
          :board
          | :bringing_bike
          | :exit
          | :park_car
          | :ride
          | :store_bike
          | :using_escalator
          | :using_wheelchair

  @type facility_activity ::
          :bringing_bike
          | :park_car
          | :store_bike
          | :using_escalator
          | :using_wheelchair
  @facility_activies [
    :bringing_bike,
    :park_car,
    :store_bike,
    :using_escalator,
    :using_wheelchair
  ]

  @type direction_id :: 0 | 1

  @type route_id :: String.t()
  @type route_type :: 0 | 1 | 2 | 3 | 4
  @type informed_entity :: %{
          optional(:activities) => [activity()],
          optional(:direction_id) => direction_id(),
          optional(:facility) => String.t(),
          optional(:route) => route_id(),
          optional(:route_type) => route_type(),
          optional(:stop) => String.t(),
          optional(:trip) => String.t()
        }

  @type lifecycle ::
          :new
          | :ongoing
          | :ongoing_upcoming
          | :upcoming

  @typedoc """
  How severe the alert it from least (`0`) to most (`10`) severe.
  """
  @type severity :: 0..10

  @type t :: %__MODULE__{
          id: id(),
          active_period: [datetime_pair()],
          banner: String.t() | nil,
          cause: cause(),
          created_at: DateTime.t(),
          description: String.t() | nil,
          effect: effect(),
          header: String.t(),
          informed_entity: [informed_entity()],
          lifecycle: lifecycle(),
          service_effect: String.t(),
          severity: severity(),
          short_header: String.t(),
          timeframe: String.t() | nil,
          updated_at: DateTime.t(),
          url: String.t() | nil
        }

  @spec all_effects :: [atom()]
  def all_effects, do: @effects

  @spec entities_with_icons(t()) :: [String.t()]
  def entities_with_icons(%__MODULE__{informed_entity: entities}) do
    entities
    |> Enum.flat_map(&routes_or_facilities/1)
    |> Enum.uniq()
  end

  @type service_type :: route_type() | :access
  @spec matches_service_type(t(), service_type) :: boolean()
  def matches_service_type(%__MODULE__{informed_entity: informed_entity}, :access),
    do: Enum.any?(informed_entity, &activities_inclued_facility_activities/1)

  def matches_service_type(%__MODULE__{informed_entity: informed_entity}, route_type),
    do: Enum.any?(informed_entity, &matches_route_type(&1, route_type))

  @spec matches_route(t(), route_id()) :: boolean()
  def matches_route(%__MODULE__{informed_entity: informed_entity}, route_id),
    do: Enum.any?(informed_entity, &entity_matches_route(&1, route_id))

  @spec matches_effect(t(), effect()) :: boolean()
  def matches_effect(%__MODULE__{effect: alert_effect}, effect) when alert_effect == effect,
    do: true

  def matches_effect(_, _), do: false

  @spec matches_route_and_effect(t(), route_id(), effect()) :: boolean()
  def matches_route_and_effect(%__MODULE__{} = alert, route_id, effect),
    do: matches_route(alert, route_id) and matches_effect(alert, effect)

  @doc """
  Duration of alert in seconds
  """
  @spec alert_duration(t()) :: integer()
  def alert_duration(alert, current_time \\ DateTime.now!("America/New_York")) do
    DateTime.diff(current_time, alert.created_at)
  end

  @spec activities_inclued_facility_activities(informed_entity()) :: boolean()
  defp activities_inclued_facility_activities(%{activities: activities}),
    do: Enum.any?(activities, &Enum.member?(@facility_activies, &1))

  defp activities_inclued_facility_activities(_),
    do: false

  @spec matches_route_type(informed_entity(), route_type()) :: boolean()
  defp matches_route_type(%{route_type: rt}, route_type) when rt == route_type, do: true
  defp matches_route_type(_, _), do: false

  @spec entity_matches_route(informed_entity(), route_id()) :: boolean()
  defp entity_matches_route(%{route: r}, route_id) when r == route_id, do: true
  defp entity_matches_route(_, _), do: false

  @spec routes_or_facilities(informed_entity()) :: [String.t()]
  defp routes_or_facilities(%{route: route_id}), do: [route_id]

  defp routes_or_facilities(%{activities: activities}) do
    activities
    |> Enum.filter(&Enum.member?(@facility_activies, &1))
    |> Enum.map(&combine_bike_activities/1)
    |> Enum.map(&Atom.to_string/1)
  end

  defp routes_or_facilities(_), do: []

  defp combine_bike_activities(:bringing_bike), do: :bike
  defp combine_bike_activities(:store_bike), do: :bike
  defp combine_bike_activities(other), do: other
end
