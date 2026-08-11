import Config

# Tests must never reach the network or open multicast sockets, so every plugin
# is disabled by default. Individual tests start the specific processes they
# exercise with explicit, controlled configuration.
config :logger, level: :warning
