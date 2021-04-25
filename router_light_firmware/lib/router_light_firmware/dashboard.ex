defmodule RouterLightFirmware.Dashboard do
  alias RouterLightFirmware.Utilities.SNMP

  @max_event_logs 30

  @derive Jason.Encoder
  defstruct stable_time: 0,
            status_color: "RED",
            last_event: 0,
            t1_latency: 0,
            t1_traffic_in: 0,
            t1_traffic_out: 0,
            lte_latency: 0,
            lte_traffic_in: 0,
            lte_traffic_out: 0,
            messages: [],
            labels: []

  def get_initial_state() do
    %__MODULE__{
      stable_time: :os.system_time(:millisecond),
      status_color: "BLUE",
      last_event: 0,
      t1_latency: 0,
      t1_traffic_in: get_empty_traffic(),
      t1_traffic_out: get_empty_traffic(),
      lte_latency: 0,
      lte_traffic_in: get_empty_traffic(),
      lte_traffic_out: get_empty_traffic(),
      messages: get_empty_messages(),
      labels: get_empty_list()
    }
  end

  def update(dashboard, cur_poll, last_poll, polling_interval) do
    dashboard
    |> update_light(cur_poll)
    |> update_stability_timer()
    |> update_sla_events(cur_poll)
    |> update_traffic(cur_poll, last_poll, polling_interval)
    |> update_event_log(cur_poll, last_poll)
  end

  # Redundancy is online
  defp update_light(dashboard, %SNMP{
         :ip_sla_10_status_code => :ONLINE,
         :ip_sla_20_status_code => :ONLINE,
         :t1_oper_status_code => :ONLINE
       }) do
    Map.put(dashboard, :status_color, "BLUE")
  end

  # LTE is impacted but T1 is fine
  defp update_light(dashboard, %SNMP{
         :ip_sla_10_status_code => :OFFLINE,
         :ip_sla_20_status_code => :ONLINE,
         :t1_oper_status_code => :ONLINE
       }) do
    Map.put(dashboard, :status_color, "GREEN")
  end

  # T1 is impacted but LTE is fine
  defp update_light(dashboard, %SNMP{
         :ip_sla_10_status_code => :ONLINE,
         :ip_sla_20_status_code => :OFFLINE,
         :t1_oper_status_code => :ONLINE
       }) do
    Map.put(dashboard, :status_color, "PURPLE")
  end

  defp update_light(dashboard, %SNMP{
         :ip_sla_10_status_code => :ONLINE,
         :ip_sla_20_status_code => :ONLINE,
         :t1_oper_status_code => :OFFLINE
       }) do
    Map.put(dashboard, :status_color, "PURPLE")
  end

  defp update_light(dashboard, %SNMP{
         :ip_sla_10_status_code => :ONLINE,
         :ip_sla_20_status_code => :OFFLINE,
         :t1_oper_status_code => :OFFLINE
       }) do
    Map.put(dashboard, :status_color, "PURPLE")
  end

  # All other combinations are failure scenarios
  defp update_light(dashboard, _) do
    Map.put(dashboard, :status_color, "RED")
  end

  defp update_stability_timer(dashboard),
    do: Map.put(dashboard, :last_event, :os.system_time(:millisecond) - dashboard.stable_time)

  defp update_event_log(
         dashboard,
         _cur_poll = %SNMP{
           :ip_sla_10_status_code => :ONLINE,
           :ip_sla_20_status_code => :ONLINE,
           :t1_oper_status_code => :ONLINE
         },
         _last_poll = %SNMP{
           :ip_sla_10_status_code => :OFFLINE,
           :ip_sla_20_status_code => :ONLINE,
           :t1_oper_status_code => :ONLINE
         }
       ) do
    message = %{
      delta_t: :os.system_time(:millisecond),
      message: "LTE SLA State (10) :OFFLINE -> :ONLINE"
    }

    dashboard
    |> Map.put(:messages, rotate_message_list(dashboard.messages, message))
    |> Map.put(:stable_time, :os.system_time(:millisecond))
  end

  defp update_event_log(
         dashboard,
         _cur_poll = %SNMP{
           :ip_sla_20_status_code => :ONLINE,
         },
         _last_poll = %SNMP{
           :ip_sla_20_status_code => :OFFLINE,
         }
       ) do
    message = %{
      delta_t: :os.system_time(:millisecond),
      message: "T1 SLA State (20) :OFFLINE -> :ONLINE"
    }

    dashboard
    |> Map.put(:messages, rotate_message_list(dashboard.messages, message))
    |> Map.put(:stable_time, :os.system_time(:millisecond))
  end

  defp update_event_log(
         dashboard,
         _cur_poll = %SNMP{
           :t1_oper_status_code => :ONLINE
         },
         _last_poll = %SNMP{
           :t1_oper_status_code => :OFFLINE
         }
       ) do
    message = %{
      delta_t: :os.system_time(:millisecond),
      message: "T1 Interface State :OFFLINE -> :ONLINE"
    }

    dashboard
    |> Map.put(:messages, rotate_message_list(dashboard.messages, message))
    |> Map.put(:stable_time, :os.system_time(:millisecond))
  end

  defp update_event_log(
         dashboard,
         _cur_poll = %SNMP{
           :t1_oper_status_code => :OFFLINE
         },
         _last_poll = %SNMP{
           :t1_oper_status_code => :ONLINE
         }
       ) do
    message = %{
      delta_t: :os.system_time(:millisecond),
      message: "T1 Interface State :ONLINE -> :OFFLINE"
    }

    dashboard
    |> Map.put(:messages, rotate_message_list(dashboard.messages, message))
    |> Map.put(:stable_time, :os.system_time(:millisecond))
  end

  defp update_event_log(
         dashboard,
         _cur_poll = %SNMP{
           :ip_sla_10_status_code => :OFFLINE,
         },
         _last_poll = %SNMP{
           :ip_sla_10_status_code => :ONLINE,
         }
       ) do
    message = %{
      delta_t: :os.system_time(:millisecond),
      message: "T1 SLA State (10) :ONLINE -> :OFFLINE"
    }

    dashboard
    |> Map.put(:messages, rotate_message_list(dashboard.messages, message))
    |> Map.put(:stable_time, :os.system_time(:millisecond))
  end

  defp update_event_log(
         dashboard,
         _cur_poll = %SNMP{
           :ip_sla_20_status_code => :OFFLINE,
         },
         _last_poll = %SNMP{
           :ip_sla_20_status_code => :ONLINE,
         }
       ) do
    message = %{
      delta_t: :os.system_time(:millisecond),
      message: "LTE SLA State (20) :ONLINE -> :OFFLINE"
    }

    dashboard
    |> Map.put(:messages, rotate_message_list(dashboard.messages, message))
    |> Map.put(:stable_time, :os.system_time(:millisecond))
  end

  defp update_event_log(dashboard, _cur_poll, _last_poll), do: dashboard

  # Redundancy is online
  defp update_sla_events(
         dashboard,
         poll_data = %SNMP{
           :ip_sla_10_status_code => :ONLINE,
           :ip_sla_20_status_code => :ONLINE,
           :t1_oper_status_code => :ONLINE
         }
       ) do
    dashboard
    |> Map.put(:t1_latency, poll_data.ip_sla_20_rtt)
    |> Map.put(:lte_latency, poll_data.ip_sla_10_rtt)
  end

  # LTE is impacted but T1 is fine
  defp update_sla_events(
         dashboard,
         poll_data = %SNMP{
           :ip_sla_10_status_code => :OFFLINE,
           :ip_sla_20_status_code => :ONLINE,
           :t1_oper_status_code => :ONLINE
         }
       ) do
    dashboard
    |> Map.put(:t1_latency, poll_data.ip_sla_20_rtt)
    |> Map.put(:lte_latency, -1)
  end

  # T1 is impacted but LTE is fine
  defp update_sla_events(
         dashboard,
         poll_data = %SNMP{
           :ip_sla_10_status_code => :ONLINE,
           :ip_sla_20_status_code => :OFFLINE,
           :t1_oper_status_code => :ONLINE
         }
       ) do
    dashboard
    |> Map.put(:t1_latency, -1)
    |> Map.put(:lte_latency, poll_data.ip_sla_10_rtt)
  end

  defp update_sla_events(
         dashboard,
         poll_data = %SNMP{
           :ip_sla_10_status_code => :ONLINE,
           :ip_sla_20_status_code => :ONLINE,
           :t1_oper_status_code => :OFFLINE
         }
       ) do
    dashboard
    |> Map.put(:t1_latency, -1)
    |> Map.put(:lte_latency, poll_data.ip_sla_10_rtt)
  end

  defp update_sla_events(
         dashboard,
         poll_data = %SNMP{
           :ip_sla_10_status_code => :ONLINE,
           :ip_sla_20_status_code => :OFFLINE,
           :t1_oper_status_code => :OFFLINE
         }
       ) do
    dashboard
    |> Map.put(:t1_latency, -1)
    |> Map.put(:lte_latency, poll_data.ip_sla_10_rtt)
  end

  # All other combinations are failure scenarios
  defp update_sla_events(dashboard, _) do
    dashboard
    |> Map.put(:t1_latency, -1)
    |> Map.put(:lte_latency, -1)
  end

  defp update_traffic(dashboard, cur_poll, last_poll, polling_interval) do
    new_t1_in =
      rotate_list(
        dashboard.t1_traffic_in,
        get_kbps(cur_poll.t1_in_octets, last_poll.t1_in_octets, polling_interval)
      )

    new_t1_out =
      rotate_list(
        dashboard.t1_traffic_out,
        get_kbps(cur_poll.t1_out_octets, last_poll.t1_out_octets, polling_interval)
      )

    new_lte_in =
      rotate_list(
        dashboard.lte_traffic_in,
        get_kbps(cur_poll.lte_in_octets, last_poll.lte_in_octets, polling_interval)
      )

    new_lte_out =
      rotate_list(
        dashboard.lte_traffic_out,
        get_kbps(cur_poll.lte_out_octets, last_poll.lte_out_octets, polling_interval)
      )

    dashboard
    |> Map.put(:t1_traffic_in, new_t1_in)
    |> Map.put(:t1_traffic_out, new_t1_out)
    |> Map.put(:lte_traffic_in, new_lte_in)
    |> Map.put(:lte_traffic_out, new_lte_out)
  end

  ############
  # PRIVATE
  ############

  # Note that this is inefficient and might be optimizable
  defp rotate_list(list, new_value) do
    tmp = list |> tl()
    tmp ++ [new_value]
  end

  # Note that this is inefficient and might be optimizable
  defp rotate_message_list(list, new_value) do
    [new_value | list]
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
  end

  defp get_kbps(_current_bps, 0, _), do: 0
  defp get_kbps(current_bps, last_bps, _) when last_bps > current_bps, do: 0

  defp get_kbps(current_bps, last_bps, polling_interval) do
    (current_bps - last_bps) / (polling_interval / 1000) / 1000 * 8
  end

  defp get_empty_traffic, do: 1..600 |> Enum.map(fn _ -> 0 end)
  defp get_empty_list, do: 1..600 |> Enum.map(fn _ -> "" end)

  defp get_empty_messages,
    do: 1..@max_event_logs |> Enum.map(fn _ -> %{delta_t: 0, message: ""} end)
end
