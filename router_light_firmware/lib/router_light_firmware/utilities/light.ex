defmodule RouterLightFirmware.Utilities.Light do
  require Logger

  alias Circuits.GPIO

  @moduledoc """
  Provides an interface to set a common-annode RGB LED to various colors.

  The RGB LED I'm using is a common-anode that receives 3.3v so pulling GPIO
  pins low for the LED ground causes the light to turn on.
  """

  @red_pin Application.get_env(:router_light_firmware, :output_pin, 17)
  @green_pin Application.get_env(:router_light_firmware, :output_pin, 22)
  @blue_pin Application.get_env(:router_light_firmware, :output_pin, 23)

  def init() do
    red_gpio =
      case GPIO.open(@red_pin, :output) do
        {:ok, gpio} -> gpio
        {:error, _} -> nil
      end

    green_gpio =
      case GPIO.open(@green_pin, :output) do
        {:ok, gpio} -> gpio
        {:error, _} -> nil
      end

    blue_gpio =
      case GPIO.open(@blue_pin, :output) do
        {:ok, gpio} -> gpio
        {:error, _} -> nil
      end

    %{
      :red => red_gpio,
      :green => green_gpio,
      :blue => blue_gpio
    }
  end

  def set_color(%{red: nil, green: nil, blue: nil}, color) do
    Logger.debug("#{color} SET (Spoofed)")
  end

  def set_color(gpio, color = "RED") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 0)
    GPIO.write(gpio.green, 1)
    GPIO.write(gpio.blue, 1)
  end

  def set_color(gpio, color = "GREEN") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 1)
    GPIO.write(gpio.green, 0)
    GPIO.write(gpio.blue, 1)
  end

  def set_color(gpio, color = "BLUE") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 1)
    GPIO.write(gpio.green, 1)
    GPIO.write(gpio.blue, 0)
  end

  def set_color(gpio, color = "PURPLE") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 0)
    GPIO.write(gpio.green, 1)
    GPIO.write(gpio.blue, 0)
  end

  def set_color(gpio, color = "YELLOW") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 0)
    GPIO.write(gpio.green, 0)
    GPIO.write(gpio.blue, 1)
  end

  def set_color(gpio, color = "CYAN") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 1)
    GPIO.write(gpio.green, 0)
    GPIO.write(gpio.blue, 0)
  end

  def set_color(gpio, color = "WHITE") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 0)
    GPIO.write(gpio.green, 0)
    GPIO.write(gpio.blue, 0)
  end

  def set_color(gpio, color = "BLACK") do
    Logger.debug("#{color} SET")
    GPIO.write(gpio.red, 1)
    GPIO.write(gpio.green, 1)
    GPIO.write(gpio.blue, 1)
  end

  def set_color(_, _, _, _), do: nil
end
