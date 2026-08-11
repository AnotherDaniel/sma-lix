import Config

# ── Runtime configuration via environment variables ─────────────────────────
#
# Evaluated at *runtime* (release boot, or `mix run`), not at compile time.
# This consolidates what SMAHub spread across a dozen Python `env_vars()`
# helpers: every plugin's environment-variable overrides live here, keeping the
# upstream variable names for drop-in Docker compatibility. Values set here are
# deep-merged over the compile-time defaults in config/config.exs.

bool = fn
  nil -> nil
  v -> String.downcase(v) in ["1", "true", "yes", "on"]
end

int = fn
  nil -> nil
  v -> String.to_integer(v)
end

# Drop keys whose value is nil (i.e. the env var was not set), so we only
# override what the operator actually provided.
compact = fn pairs -> for {k, v} <- pairs, v != nil, do: {k, v} end

# Global verbosity (SMAHUB_VERBOSE / SMAHUB_VERBOSER)
cond do
  bool.(System.get_env("SMAHUB_VERBOSER")) -> config :logger, level: :debug
  bool.(System.get_env("SMAHUB_VERBOSE")) -> config :logger, level: :info
  true -> :ok
end

ident_postfix = System.get_env("IDENT_POSTFIX")

# ── Sources ─────────────────────────────────────────────────────────────────

config :sma_lix,
       SmaLix.Sources.Demo,
       compact.(enabled: bool.(System.get_env("DEMOSOURCE_ENABLED")))

config :sma_lix,
       SmaLix.Sources.SHM2,
       compact.(
         enabled: bool.(System.get_env("SHM2_ENABLED")),
         update_freq: int.(System.get_env("SHM2_UPDATEFREQ")),
         sensor_prefix: System.get_env("SHM2_PREFIX")
       )

config :sma_lix,
       SmaLix.Sources.TripowerX,
       compact.(
         enabled: bool.(System.get_env("TRIPOWERX_ENABLED")),
         address: System.get_env("TRIPOWERX_ADDRESS"),
         protocol: System.get_env("TRIPOWERX_PROTOCOL"),
         verify_tls: bool.(System.get_env("TRIPOWERX_VERIFYTLS")),
         username: System.get_env("TRIPOWERX_USER"),
         password: System.get_env("TRIPOWERX_PASSWORD"),
         update_freq: int.(System.get_env("TRIPOWERX_UPDATEFREQ")),
         sensor_prefix: System.get_env("TRIPOWERX_PREFIX"),
         ident_postfix: ident_postfix
       )

config :sma_lix,
       SmaLix.Sources.EvCharger,
       compact.(
         enabled: bool.(System.get_env("EVCHARGER_ENABLED")),
         address: System.get_env("EVCHARGER_ADDRESS"),
         protocol: System.get_env("EVCHARGER_PROTOCOL"),
         verify_tls: bool.(System.get_env("EVCHARGER_VERIFYTLS")),
         username: System.get_env("EVCHARGER_USER"),
         password: System.get_env("EVCHARGER_PASSWORD"),
         update_freq: int.(System.get_env("EVCHARGER_UPDATEFREQ")),
         sensor_prefix: System.get_env("EVCHARGER_PREFIX")
       )

# ── Sinks ───────────────────────────────────────────────────────────────────

config :sma_lix,
       SmaLix.Sinks.Demo,
       compact.(enabled: bool.(System.get_env("DEMOSINK_ENABLED")))

config :sma_lix,
       SmaLix.Sinks.Mqtt,
       compact.(
         enabled: bool.(System.get_env("MQTT_ENABLED")),
         address: System.get_env("MQTT_ADDRESS"),
         port: int.(System.get_env("MQTT_PORT")),
         username: System.get_env("MQTT_USER"),
         password: System.get_env("MQTT_PASSWORD"),
         # kept as raw string ("1"/"2"/false) to match upstream semantics
         tls: System.get_env("MQTT_TLS"),
         tls_insecure: bool.(System.get_env("MQTT_TLS_INSECURE")),
         update_freq: int.(System.get_env("MQTT_UPDATEFREQ")),
         publish_units: bool.(System.get_env("MQTT_PUBLISHUNITS")),
         ident_postfix: ident_postfix
       )

config :sma_lix,
       SmaLix.Sinks.HaMqtt,
       compact.(
         enabled: bool.(System.get_env("HA_MQTT_ENABLED")),
         address: System.get_env("HA_MQTT_ADDRESS"),
         port: int.(System.get_env("HA_MQTT_PORT")),
         username: System.get_env("HA_MQTT_USER"),
         password: System.get_env("HA_MQTT_PASSWORD"),
         update_freq: int.(System.get_env("HA_MQTT_UPDATEFREQ")),
         discovery_prefix: System.get_env("HA_MQTT_PREFIX"),
         ident_postfix: ident_postfix
       )

config :sma_lix,
       SmaLix.Sinks.GenHaSensors,
       compact.(
         enabled: bool.(System.get_env("GENHASENSORS_ENABLED")),
         generate_freq: int.(System.get_env("GENHASENSORS_GENERATEFREQ")),
         filename_prefix: System.get_env("GENHASENSORS_FILEPREFIX")
       )
