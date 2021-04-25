defmodule RouterLightFirmware.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: RouterLightFirmware.Supervisor]

    children =
      [
        {RouterLightFirmware.SNMPPoller, []},
        {RouterLightFirmware.StatusLight, []}
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  def children(:host) do
    []
  end

  def children(_target) do
    []
  end

  def target() do
    Application.get_env(:router_light_firmware, :target)
  end
end
