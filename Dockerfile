# --- Set up Elixir build ---
FROM hexpm/elixir:1.14.3-erlang-25.2.2-debian-bullseye-20230109-slim as elixir-builder

ENV LANG=C.UTF-8 MIX_ENV=prod

RUN apt-get update --allow-releaseinfo-change
RUN apt-get install --no-install-recommends --yes \
  build-essential ca-certificates git
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /root
ADD . .
RUN mix deps.get --only prod


# --- Build Elixir release ---
FROM elixir-builder as app-builder

WORKDIR /root
RUN mix compile
RUN mix phx.digest
RUN mix release


# --- Set up runtime container ---
FROM debian:bullseye-slim

ENV LANG=C.UTF-8 MIX_ENV=prod REPLACE_OS_VARS=true

RUN apt-get update --allow-releaseinfo-change \
  && apt-get install --no-install-recommends --yes dumb-init \
  && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN addgroup --system alertsviewer && adduser --system --ingroup alertsviewer alertsviewer
USER alertsviewer

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

WORKDIR /home/alertsviewer
COPY --from=app-builder --chown=alertsviewer:alertsviewer  /root/_build/prod/rel/alerts_viewer .

# HTTP
EXPOSE 4000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

HEALTHCHECK CMD ["bin/alerts_viewer", "rpc", "1 + 1"]
CMD ["bin/alerts_viewer", "start"]
