# AlertsViewer Architecture

## Overview

AlertsViewer is an Elixir application with a Phoenix web layer using LiveView for the user experience.

## Data Sources

AlertsViewer gets data from the following sources.

### MBTA V3 API

The [MBTA API](https://www.mbta.com/developers/v3-api) provides information about bus routes. We also use its [streaming capabilities](https://www.mbta.com/developers/v3-api/streaming) to get service alerts.

### Swiftly

Swiftly is a company we use to provide predictions for our bus arrivals. As a part of this, they provide a real-time bus vehicle data feed. This largely overlaps with the Vehicle Positions data we generate as part of our [GTFS-rt feed](https://www.mbta.com/developers/gtfs-realtime), but they include some extra data. In particul far this application, they include a measurement of the bus's current "schedule adherence", which is how late or early they are from where they should be right now based on the schedule.

### GTFS-realtime Trip Updates

We use the [GTFS-realtime Trip Updates feed](https://s3.amazonaws.com/mbta-busloc-s3/staging/TripUpdates_enhanced.json) to get information about trip updates and stop updates.