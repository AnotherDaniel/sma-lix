# Multi-stage build producing a self-contained OTP release.
#
# Image tags are build args so you can match your target Erlang/Elixir; the
# defaults are recent stable slim images. Override with:
#   docker build --build-arg ELIXIR_IMAGE=... --build-arg RUNTIME_IMAGE=... .
ARG ELIXIR_IMAGE=hexpm/elixir:1.18.4-erlang-27.3.4-debian-bookworm-20250630-slim
ARG RUNTIME_IMAGE=debian:bookworm-slim

# ── Build stage ──────────────────────────────────────────────────────────────
FROM ${ELIXIR_IMAGE} AS build

RUN apt-get update -y && apt-get install -y build-essential git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

# Dependencies first, for better layer caching.
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Application sources.
COPY config config
COPY lib lib

RUN mix compile
RUN mix release

# ── Runtime stage ────────────────────────────────────────────────────────────
FROM ${RUNTIME_IMAGE} AS app

RUN apt-get update -y \
    && apt-get install -y libstdc++6 openssl libncurses6 locales ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

WORKDIR /app
RUN useradd --create-home --uid 1000 app

COPY --from=build /app/_build/prod/rel/sma_lix ./
RUN chown -R app: /app
USER app

ENTRYPOINT ["/app/bin/sma_lix"]
CMD ["start"]
