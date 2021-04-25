defmodule RouterLightFirmware.Utilities.SNMP do
  require Logger

  defstruct t1_in_octets: 0,
            t1_out_octets: 0,
            lte_in_octets: 0,
            lte_out_octets: 0,
            ip_sla_10_rtt: 0,
            ip_sla_10_status_code: :OFFLINE,
            ip_sla_20_rtt: 0,
            ip_sla_20_status_code: :OFFLINE,
            t1_oper_status_code: :OFFLINE,
            response_time: 0

  def poll_batman() do
    :snmpm.sync_get('default_user', 'batman_agent', [
      # T1 Input Octets
      [1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1],
      # T1 Output Octets
      [1, 3, 6, 1, 2, 1, 2, 2, 1, 16, 1],
      # LTE Input Octets
      [1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 3],
      # LTE Output Octets
      [1, 3, 6, 1, 2, 1, 2, 2, 1, 16, 3],
      # IP SLA 10 RTT (LTE)
      [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 1, 10],
      # IP SLA 10 Status (LTE)
      [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 2, 10],
      # IP SLA 20 RTT (T1)
      [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 1, 20],
      # IP SLA 20 Status (T1)
      [1, 3, 6, 1, 4, 1, 9, 9, 42, 1, 2, 10, 1, 2, 20],
      # T1 Interface Operational Status
      [1, 3, 6, 1, 2, 1, 2, 2, 1, 8, 1]
    ])
    |> decode_batman_snmp()
  end

  defp decode_batman_snmp({:ok, _, _} = snmp_response) do
    {_,
     {_, _,
      [
        {_, _, _, t1_in_octets, _},
        {_, _, _, t1_out_octets, _},
        {_, _, _, lte_in_octets, _},
        {_, _, _, lte_out_octets, _},
        {_, _, _, ip_sla_10_rtt, _},
        {_, _, _, ip_sla_10_status_code, _},
        {_, _, _, ip_sla_20_rtt, _},
        {_, _, _, ip_sla_20_status_code, _},
        {_, _, _, t1_if_oper_status_code, _}
      ]}, response_time} = snmp_response

    %__MODULE__{
      :t1_in_octets => t1_in_octets,
      :t1_out_octets => t1_out_octets,
      :lte_in_octets => lte_in_octets,
      :lte_out_octets => lte_out_octets,
      :ip_sla_10_rtt => ip_sla_10_rtt,
      :ip_sla_10_status_code => sla_status_code_to_atom(ip_sla_10_status_code),
      :ip_sla_20_rtt => ip_sla_20_rtt,
      :ip_sla_20_status_code => sla_status_code_to_atom(ip_sla_20_status_code),
      :t1_oper_status_code => if_oper_status_code_to_atom(t1_if_oper_status_code),
      :response_time => 5000 - response_time
    }
  end

  defp decode_batman_snmp({:error, _, _}) do
    %{
      :ip_sla_10_rtt => -1,
      :ip_sla_10_status_code => sla_status_code_to_atom(666),
      :ip_sla_20_rtt => -1,
      :ip_sla_20_status_code => sla_status_code_to_atom(666),
      :t1_oper_status_code => if_oper_status_code_to_atom(666)
    }
  end

  defp decode_batman_snmp({:error, {:timeout, _}}) do
    %{
      :ip_sla_10_rtt => -1,
      :ip_sla_10_status_code => sla_status_code_to_atom(666),
      :ip_sla_20_rtt => -1,
      :ip_sla_20_status_code => sla_status_code_to_atom(666),
      :t1_oper_status_code => if_oper_status_code_to_atom(666)
    }
  end

  defp sla_status_code_to_atom(4), do: :OFFLINE
  defp sla_status_code_to_atom(1), do: :ONLINE
  defp sla_status_code_to_atom(_), do: UNKNOWN

  defp if_oper_status_code_to_atom(2), do: :OFFLINE
  defp if_oper_status_code_to_atom(1), do: :ONLINE
  defp if_oper_status_code_to_atom(_), do: :UNKNOWN

end
