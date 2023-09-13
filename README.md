# AlertsViewer

AlertsViewer is an internal project helping us with myriad alert-related needs. It allows us to:

- explore alert data
- explore existing bus delay alerts
- experiment with determining when alerts should be created


## Architecture

[AlertsViewer application architecture](ARCHITECTURE.md)

## Setup

### Requirements

- MBTA API key (get one [here](https://api-dev.mbtace.com))
  - You may need to request an increased rate limit if you get errors during
    the first app startup; 2000 requests per minute should be enough
- [`asdf`](https://asdf-vm.com/) with plugins: `elixir`, `erlang`

### Instructions

1. `asdf install`
2. `mix deps.get`
4. `cp .env.example .env`
5. In `.env`: Fill in `API_KEY=` with the API key you obtained above. Obtain the `SWIFTLY_AUTHORIZATION_KEY` from the shared vault in 1password, and fill it in too.
6. Export the variables in `.env`, eg in bash `set -a && . .env && set +a`
7. `mix ecto.setup`
8. `MIX_ENV=test mix ecto.setup`

### Running tests

- `mix test`

## Development

To start your Phoenix server:

- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Flags

This project uses the [Laboratory](https://github.com/paulswartz/laboratory) library to manage user flags. These flags are per-user, saved in local browser storage, and expire every 30 days. To see what flags are available and set them for yourself, visit the `/_flags` route (you may need to refresh the page to see a change). To add new flags, set them in the config file. They will automatically be available as assigns in both regular and live view pages.
