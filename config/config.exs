import Config

# Which plugins are wired into the supervision tree. Enabling/disabling an
# individual plugin at runtime is done via its own `:enabled` flag (see below and
# config/runtime.exs), not by editing this list — this list only decides which
# plugin modules exist as potential children.
config :sma_lix,
  sources: [
    SmaLix.Sources.Demo,
    SmaLix.Sources.SHM2,
    SmaLix.Sources.TripowerX,
    SmaLix.Sources.EvCharger
  ],
  sinks: [
    SmaLix.Sinks.Demo,
    SmaLix.Sinks.Mqtt,
    SmaLix.Sinks.HaMqtt,
    SmaLix.Sinks.GenHaSensors
  ]

# ── Source plugins ──────────────────────────────────────────────────────────

config :sma_lix, SmaLix.Sources.Demo,
  enabled: false,
  interval: :timer.seconds(5),
  message: "Hello, world!"

config :sma_lix, SmaLix.Sources.SHM2,
  enabled: false,
  # seconds between processed multicast frames (the meter emits ~1/s)
  update_freq: 2,
  sensor_prefix: "SHM2.",
  multicast_group: "239.12.255.254",
  multicast_port: 9522,
  bind_address: "0.0.0.0"

config :sma_lix, SmaLix.Sources.TripowerX,
  enabled: false,
  address: "192.0.2.1",
  protocol: "https",
  verify_tls: false,
  username: "user",
  password: "pwd",
  update_freq: 2,
  sensor_prefix: "TriPowerX.",
  ident_postfix: ""

config :sma_lix, SmaLix.Sources.EvCharger,
  enabled: false,
  address: "192.0.2.1",
  protocol: "https",
  verify_tls: false,
  username: "user",
  password: "pwd",
  update_freq: 2,
  sensor_prefix: "EVCharger."

# ── Sink plugins ────────────────────────────────────────────────────────────

config :sma_lix, SmaLix.Sinks.Demo,
  enabled: false,
  interval: :timer.seconds(5)

config :sma_lix, SmaLix.Sinks.Mqtt,
  enabled: false,
  address: "192.0.2.1",
  port: 1883,
  username: nil,
  password: nil,
  # false | "1" (TLSv1.1) | "2" (TLSv1.2)
  tls: false,
  tls_insecure: false,
  # seconds between full republishes of all collected data
  update_freq: 60,
  # publish {value, unit} tuples verbatim, or only the value
  publish_units: false,
  ident_postfix: ""

config :sma_lix, SmaLix.Sinks.HaMqtt,
  enabled: false,
  address: "192.0.2.1",
  port: 1883,
  username: nil,
  password: nil,
  update_freq: 10,
  discovery_prefix: "homeassistant",
  ident_postfix: ""

config :sma_lix, SmaLix.Sinks.GenHaSensors,
  enabled: false,
  generate_freq: 60,
  filename_prefix: "hasensors_",
  output_dir: ".",
  icons: %{
    "SHM2" => "mdi:camera-switch",
    "TriPowerX" => "mdi:border-all"
  }

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:plugin]

import_config "#{config_env()}.exs"
