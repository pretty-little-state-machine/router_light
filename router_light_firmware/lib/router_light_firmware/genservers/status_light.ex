defmodule RouterLightFirmware.StatusLight do
  use GenServer
  require Logger

  alias RouterLightFirmware.Utilities.Light

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :StatusLight)
  end

  def change_color(pid, color) do
    GenServer.cast(pid, {:change_color, color})
  end

  # Callbacks

  @impl true
  def init(:ok) do
    gpio_map = Light.init()
    Logger.debug("StatusLight Initialized")
    Light.set_color(gpio_map, "YELLOW")
    {:ok, gpio_map}
  end

  @impl true
  def handle_cast({:change_color, color}, gpio_map) do
    issue_color_change(gpio_map, color)
    {:noreply, gpio_map}
  end

  defp issue_color_change(gpio_map, color) do
    Logger.debug("Changing color to #{color}")
    Light.set_color(gpio_map, color)
  end
end
