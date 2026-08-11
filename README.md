# SmaLix

**SmaLix** is an Elixir/OTP port of [SMAHub](https://github.com/AnotherDaniel/smahub):
a flexible, plugin-based daemon for collecting data from SMA photovoltaic (PV)
products — solar inverters and energy meters — and publishing it to output
channels such as MQTT and Home Assistant.

The name is simply *SMA + Elixir*.

## What it does

SmaLix periodically (or reactively) reads data from SMA devices via **source**
plugins, funnels everything through a single in-memory store, and re-publishes
it via **sink** plugins.

```
                +-------------+
                |   SmaLix    |
                +------+------+
                       |
         +-------------+--------------+
         |                            |
         v                            v
     +--------+                  +--------+
     | Source |   --> Store -->  |  Sink  |
     | Plugin |    (pub/sub)     | Plugin |
     +--------+                  +--------+
```

### Bundled plugins

Sources:

- **SHM2** — SMA Sunny Home Manager 2 / energy meters, via the Speedwire
  multicast protocol (binary UDP).
- **TripowerX** — SMA Tripower X inverters, via the built-in HTTP/JSON API.
- **EvCharger** — SMA EV Charger, via its HTTP/JSON API.
- **Demo** — emits a counter; useful for testing.

Sinks:

- **Mqtt** — publishes values to a plain MQTT broker.
- **HaMqtt** — publishes to Home Assistant using MQTT autodiscovery.
- **GenHaSensors** — generates Home Assistant MQTT-sensor YAML files.
- **Demo** — logs changes and periodically prints the full data set.

## How it maps to (and improves on) SMAHub

This is an idiomatic OTP rewrite, not a line-by-line translation. The behaviour
is preserved; the machinery is Elixir-native:

| SMAHub (Python) | SmaLix (Elixir/OTP) |
| --- | --- |
| `SMA_Dict` (dict + `threading.Lock` + callback list) | `SmaLix.Store`: an ETS table for lock-free concurrent reads, a `GenServer` serialising writes/dedup, and a `Registry` for change pub/sub |
| Dir-scanned `.py` files exposing `execute(...)` | Compiled `SmaLix.Source` / `SmaLix.Sink` behaviours, supervised as GenServers |
| `dostop()` polling flag + manual threads | OTP supervision; stopping is just process shutdown |
| Global `SENSOR_REGISTRY` dict | `SmaLix.SensorRegistry` (ETS) with typed `SmaLix.Sensor` structs |
| A dozen per-plugin `env_vars()` helpers | One `config/runtime.exs` mapping env vars → config |
| Manual byte-offset Speedwire decode | `SmaLix.Speedwire` via binary pattern matching |
| Near-duplicate `tripowerx.py` / `evcharger.py` | Shared `SmaLix.Sources.SmaHttpApi` |
| `paho-mqtt` reconnect loop | `Tortoise311` (handles reconnection itself) |
| `ha_mqtt_discoverable` dependency | Discovery protocol implemented directly over MQTT |

## Requirements

- Elixir ~> 1.16 and a matching Erlang/OTP (developed against Elixir 1.20 /
  OTP 29).

## Running

Fetch dependencies and run the test suite:

```shell
mix deps.get
mix test
```

Run the daemon in the foreground:

```shell
mix run --no-halt
```

All plugins are **disabled by default**. Enable and configure them via
environment variables (below) or by editing `config/config.exs`. For example,
to try the demo source and sink:

```shell
DEMOSOURCE_ENABLED=true DEMOSINK_ENABLED=true mix run --no-halt
```

## Configuration

Compile-time defaults live in `config/config.exs`, one block per plugin keyed by
its module, e.g.:

```elixir
config :sma_lix, SmaLix.Sources.SHM2,
  enabled: false,
  update_freq: 2,
  sensor_prefix: "SHM2."
```

Runtime overrides come from environment variables (`config/runtime.exs`), using
the **same variable names as SMAHub** for drop-in compatibility.

### Environment variables

Global:

| Variable | Effect |
| --- | --- |
| `SMAHUB_VERBOSE` | Set log level to `info` |
| `SMAHUB_VERBOSER` | Set log level to `debug` |
| `IDENT_POSTFIX` | Suffix appended to device names / MQTT client IDs (for multiple instances) |

Sources:

| Variable | Plugin | Meaning |
| --- | --- | --- |
| `DEMOSOURCE_ENABLED` | Demo | Enable |
| `SHM2_ENABLED` / `SHM2_UPDATEFREQ` / `SHM2_PREFIX` | SHM2 | Enable / seconds between frames / key prefix |
| `TRIPOWERX_ENABLED` | TripowerX | Enable |
| `TRIPOWERX_ADDRESS` / `TRIPOWERX_PROTOCOL` / `TRIPOWERX_VERIFYTLS` | TripowerX | Host / `http`\|`https` / verify TLS |
| `TRIPOWERX_USER` / `TRIPOWERX_PASSWORD` | TripowerX | Credentials |
| `TRIPOWERX_UPDATEFREQ` / `TRIPOWERX_PREFIX` | TripowerX | Poll interval (s) / key prefix |
| `EVCHARGER_*` | EvCharger | Same shape as `TRIPOWERX_*` |

Sinks:

| Variable | Plugin | Meaning |
| --- | --- | --- |
| `DEMOSINK_ENABLED` | Demo | Enable |
| `MQTT_ENABLED` | Mqtt | Enable |
| `MQTT_ADDRESS` / `MQTT_PORT` | Mqtt | Broker host / port |
| `MQTT_USER` / `MQTT_PASSWORD` | Mqtt | Credentials |
| `MQTT_TLS` / `MQTT_TLS_INSECURE` | Mqtt | `1`=TLSv1.1, `2`=TLSv1.2 / skip verify |
| `MQTT_UPDATEFREQ` / `MQTT_PUBLISHUNITS` | Mqtt | Full-republish interval (s) / publish value/unit pairs |
| `HA_MQTT_ENABLED` | HaMqtt | Enable |
| `HA_MQTT_ADDRESS` / `HA_MQTT_PORT` | HaMqtt | Broker host / port (defaults to 1883) |
| `HA_MQTT_USER` / `HA_MQTT_PASSWORD` | HaMqtt | Credentials |
| `HA_MQTT_UPDATEFREQ` / `HA_MQTT_PREFIX` | HaMqtt | Sweep interval (s) / discovery prefix |
| `GENHASENSORS_ENABLED` | GenHaSensors | Enable |
| `GENHASENSORS_GENERATEFREQ` / `GENHASENSORS_FILEPREFIX` | GenHaSensors | Generate interval (s) / filename prefix |

## Docker

Build and run with the provided `Dockerfile` / `docker-compose.yml`:

```shell
docker compose build
# edit docker-compose.yml to set your devices / broker
docker compose up -d
```

The container runs on the host network (needed for SHM2 Speedwire multicast).

## Writing a plugin

A source is a module that `use`s `SmaLix.Source`:

```elixir
defmodule MyApp.Sources.Thing do
  use SmaLix.Source

  @impl true
  def setup(config), do: {:ok, %{n: 0}, config[:interval]}

  @impl true
  def poll(%{n: n} = state), do: {:emit, [{"thing.value", n}], %{state | n: n + 1}}
end
```

Add it to the `:sources` list in `config/config.exs`. See `SmaLix.Source` and
`SmaLix.Sink` for the full behaviour documentation.

## License

GPL-2.0, following upstream. See [`LICENSE`](LICENSE).

SmaLix is a port of [SMAHub](https://github.com/AnotherDaniel/smahub) by
AnotherDaniel, which was in turn inspired by and adapted from:

- Sven (littleyoda) — [Home-Assistant-Tripower-X-MQTT](https://github.com/littleyoda/Home-Assistant-Tripower-X-MQTT)
- Wenger Florian (datenschuft) — [SMA-EM](https://github.com/datenschuft/SMA-EM)
