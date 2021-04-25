defmodule RouterLightFirmwareTest do
  use ExUnit.Case
  doctest RouterLightFirmware

  test "snmp_results_can_be_parsed" do
    snmp_response =
      {:ok,
       {:noError, 0,
        [
          {:varbind, [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 1, 10], :Unsigned32, 80, 1},
          {:varbind, [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 2, 10], :INTEGER, 1, 2},
          {:varbind, [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 1, 20], :Unsigned32, 8, 3},
          {:varbind, [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 2, 20], :INTEGER, 1, 4}
        ]}, 4996}
  end
end
