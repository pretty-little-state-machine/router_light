# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

config :router_light_firmware, target: Mix.target()

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1618945542"

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

if Mix.target() == :host or Mix.target() == :"" do
  import_config "host.exs"
else
  import_config "target.exs"
end

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures the endpoint
config :router_light_ui, RouterLightUiWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 8000],
  secret_key_base: "MdEAzm1GZPwKaQsfKfAOr8M8Sr6omSPxusUoYuROuleFoG0U4BKsOwlEYeQUfnzB",
  root: Path.dirname(__DIR__),
  server: true,
  render_errors: [view: RouterLightUiWeb.ErrorView, accepts: ~w(html json), layout: false],
  live_view: [signing_salt: "4HvPjKB7"],
  pubsub: [name: Nerves.PubSub, adapter: Phoenix.PubSub.PG2],
  code_reloader: false
