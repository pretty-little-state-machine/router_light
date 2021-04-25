# Router Light

A personal project to experiment with the [Nerves](https://www.nerves-project.org/) IOT framework.
There is a blog writeup about this project here: 
[ItWasScience Blog](https://www.itwasscience.com/blog/router-light)

This project serves as a sub-second monitoring system for my home router's two internet 
connections. It provides a physical view with an LED as well as a UI served by Phoenix.

The SNMP polls, light updates and UI updates occur every 300 milliseconds.

![Picture of Light](images/hardware.jpg?raw=true)

**UI - Insprired by Evangelion's NERV systems**
![Picture of UI](images/ui_short.gif?raw=true)

Below are both child READMEs:

# Router_Light_UI

A GUI for the NERV UI frontend. Follow the typical Phoenix instructions to install below.

There are only two pages:

`/` - Index - Shows the live connection monitor - **Should not be used unless the firmware is 
also running**

`/mock` - Shows a mock dashboard fed with fake data for dashboard testing - If you are
just curious about the project this is the path you want to run as it doesn't rely on 
any firmware functionality.

# Router_Light_Firmware

A simple Nerves project using the Erlang SNMP application as a manager to monitor 
my home router internet status and set an indicator light using GPIO pins. We have
two internet connections at our house: a T1 interface for our low-latency traffic 
and an LTE modem that we shunt everything else to.

| T1 IfOper State    | T1 SLA State (20)  | LTE SLA State (10) | Status Color           |
| ------------------ | ------------------ |--------------------|----------------------- |
| :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :blue_square: Blue     |
| :heavy_check_mark: | :heavy_check_mark: | :x:                | :green_square: Green   |
| :x:                | :heavy_check_mark: | :heavy_check_mark: | :purple_square: Purple |
| :heavy_check_mark: | :x:                | :heavy_check_mark: | :purple_square: Purple |
| :x:                | :x:                | :heavy_check_mark: | :purple_square: Purple |
| :x:                | :x:                | :x:                | :red_square: Red       |

The indicator is set to yellow until the system initially polls the router.

## Checking Internet Health
Each connection has a static route that forces an IP SLA probe over that specific
internet connection. ICMP echos are sent every 3 seconds on the LTE and every 60
seconds on the T1. Since the T1 probe is so slow to notify the physical interface 
itself is monitored as well.

The SNMP poller runs every 300 milliseconds and typically takes <10ms to receive
a response from my home router.

```#show ip sla statistics details
IPSLAs Latest Operation Statistics

IPSLA operation id: 10
	Latest RTT: 59 milliseconds
Latest operation start time: 23:10:16 EDT Tue Apr 20 2021
Latest operation return code: OK
...SNIP...

IPSLA operation id: 20
	Latest RTT: 8 milliseconds
Latest operation start time: 23:10:01 EDT Tue Apr 20 2021
Latest operation return code: OK
...SNIP...
```

These are available using the RTTMON SNMP OIDs:

```
# IP SLA 10 RTT
[1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 1, 10],
# IP SLA 10 Status
[1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 2, 10],
# IP SLA 20 RTT
[1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 1, 20],
# IP SLA 20 Status
[1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 2, 20],
```

The IfOperStatus of the T1 interface is at this OID on my hardware:

```
# T1 Interface Operational Status
[1, 3, 6, 1, 2, 1, 2, 2, 1, 8, 1]
```

You can see the logic for decoding the SNMP response into a map inside of
`lib/router_light_firmware/utilities/snmp.ex`.

## GenServers

There are two named GenServers in this application: `StatusLight` and `Poller`.

StatusLight is responsible for initializing the GPIO pins and implements a 
`{:change_color, color}` cast so that the poller can request a color to be
set on the LED.

Poller calls itself with `handle_info/2` on a schedule to poll the router 
agent and determine the appropriate color to request from the StatusLight.
Should the network be unavailable the GenServer will crash (SNMP Error) and
continually be restarted until the network is available again. OTP fault 
tolerance at it's finest!

## SNMP Path Setup

The Erlang SNMP application requires static configuration files to set up the
manager, agents and users. These three files must be present in the filesystem
so this project places them inside the `rootfs_overlay/snmp` folder. The 
applciation also requires a read-write path for the database file. This will be
created if it doesn't exist so I have specified `/tmp`. This avoids having to 
modify the baseline partitioning scheme for my build target (rpi0).

The relevant lines for these paths may be found in the two configuration files:

**config/host.exs**  
```config :snmp, :manager, config: [dir: './rootfs_overlay/snmp', db_dir: '/tmp']```

**config/target.exs**  
```config :snmp, :manager, config: [dir: '/snmp', db_dir: '/tmp']```

Note the use of the relative path for my host environment while an absolute path
is specified for the build target.

Thanks to Ernie Miller on this post whic details the configuration files for SNMP:
[SNMP in Elixir](https://ernie.io/2014/07/10/snmp-in-elixir/) 

**Caveat Emptor**  
This appears to work but I am new to Nerves and there may be side-effects of this
approach that I do not yet know.


# Nerves Built-in Readme

The following come as part of a new Nerves project and are left here as a 
reference.

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
