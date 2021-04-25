defmodule RouterLightUiWeb.MockLive do
  use RouterLightUiWeb, :live_view

  @update_interval 333

  @impl true
  def mount(_params, _session, socket) do
    state = %{
      start_time: :os.system_time(:millisecond),
      status_color: "BLUE",
      last_event: 0,
      t1_latency: :rand.uniform(8) + 6,
      t1_traffic_in: get_t1_in_points(),
      t1_traffic_out: get_t1_out_points(),
      lte_latency:  :rand.uniform(32) + 64,
      lte_traffic_in: get_lte_in_points(),
      lte_traffic_out: get_lte_out_points(),
      messages: [],
    }

    send(self(), {:update_dashboard, state})
    {:ok, assign(socket, state)}
  end

  @impl true
  def handle_info({:update_dashboard, state}, socket) do

    x = :rand.uniform(100)
    new_state = cond do
      0 < x and x < 10 ->
        state
        |> cause_event(:restore_lte)
        |> update_state()
      10 < x and x < 20 ->
        state
        |> cause_event(:restore_t1)
        |> update_state()
      20 < x and x < 25 ->
        state
        |> cause_event(:fail_lte)
        |> update_state()
      30 < x and x < 35 ->
          state
          |> cause_event(:fail_t1)
          |> update_state()
      95 < x and x < 100 ->
        state
        |> cause_event(:restore_t1)
        |> cause_event(:restore_lte)
        |> update_state()
      true ->
        state |> update_state()
    end

    Process.sleep(@update_interval)
    send(self(), {:update_dashboard, new_state})
    {:noreply, socket |> push_event("dashboard", new_state)}
  end

  defp rotate_list(list, new_value) do
    tmp = list |> tl()
    tmp ++ [new_value]
  end

  defp get_t1_in_points, do: 1..600 |> Enum.map(fn _ -> :rand.uniform(750) end)
  defp get_t1_out_points, do: 1..600 |> Enum.map(fn _ ->  -1 * :rand.uniform(200) end)
  defp get_lte_in_points, do: 1..600 |> Enum.map(fn _ -> :rand.uniform(20_000) end)
  defp get_lte_out_points, do: 1..600 |> Enum.map(fn _ ->  -1 * :rand.uniform(1500) end)
  defp get_empty_list, do: 1..600 |> Enum.map(fn _ ->  "" end)

  defp update_state(state = %{t1_latency: -1, lte_latency: -1}) do
    %{
      start_time: state.start_time,
      status_color: "RED",
      last_event: state.last_event + @update_interval,
      t1_latency: -1,
      t1_traffic_in: rotate_list(state.t1_traffic_in, 0),
      t1_traffic_out: rotate_list(state.t1_traffic_out, 0),
      lte_latency: -1,
      lte_traffic_in: rotate_list(state.lte_traffic_in, 0),
      lte_traffic_out: rotate_list(state. lte_traffic_out, 0),
      labels: get_empty_list(),
      messages: state.messages
    }
  end

  defp update_state(state = %{lte_latency: -1}) do
    %{
      start_time: state.start_time,
      status_color: "GREEN",
      last_event: state.last_event + @update_interval,
      t1_latency: :rand.uniform(8) + 6,
      t1_traffic_in: rotate_list(state.t1_traffic_in, :rand.uniform(600)),
      t1_traffic_out: rotate_list(state.t1_traffic_out, -1 * :rand.uniform(200)),
      lte_latency: -1,
      lte_traffic_in: rotate_list(state.lte_traffic_in, 0),
      lte_traffic_out: rotate_list(state. lte_traffic_out, 0),
      labels: get_empty_list(),
      messages: state.messages
    }
  end

  defp update_state(state = %{t1_latency: -1}) do
    %{
      start_time: state.start_time,
      status_color: "PURPLE",
      last_event: state.last_event + @update_interval,
      t1_latency: -1,
      t1_traffic_in: rotate_list(state.t1_traffic_in, 0),
      t1_traffic_out: rotate_list(state.t1_traffic_out, 0),
      lte_latency: :rand.uniform(30) + 68,
      lte_traffic_in: rotate_list(state.lte_traffic_in, :rand.uniform(20_000)),
      lte_traffic_out: rotate_list(state. lte_traffic_out, -1 * :rand.uniform(1_500)),
      labels: get_empty_list(),
      messages: state.messages
    }
  end

  defp update_state(state) do
    %{
      start_time: state.start_time,
      status_color: "BLUE",
      last_event: state.last_event + @update_interval,
      t1_latency: :rand.uniform(8) + 6,
      t1_traffic_in: rotate_list(state.t1_traffic_in, :rand.uniform(600)),
      t1_traffic_out: rotate_list(state.t1_traffic_out, -1 * :rand.uniform(200)),
      lte_latency: :rand.uniform(30) + 68,
      lte_traffic_in: rotate_list(state.lte_traffic_in, :rand.uniform(20_000)),
      lte_traffic_out: rotate_list(state. lte_traffic_out, -1 * :rand.uniform(1_500)),
      labels: get_empty_list(),
      messages: state.messages
    }
  end

  defp cause_event(state = %{t1_latency: t1_latency}, :fail_t1) when t1_latency > 0 do
    delta_t = :os.system_time(:millisecond) - state.start_time
    new_messages = [%{delta_t: delta_t, message: "IP SLA PROBE 10 STATE DOWN - T1 FAILURE"} | state.messages]

    state
    |> Map.put(:last_event, 0)
    |> Map.put(:t1_latency, -1)
    |> Map.put(:messages,  new_messages)
  end

  defp cause_event(state = %{lte_latency: lte_latency}, :fail_lte) when lte_latency > 0 do
    delta_t = :os.system_time(:millisecond) - state.start_time
    new_messages = [%{delta_t: delta_t, message: "IP SLA PROBE 20 STATE DOWN - LTE FAILURE"} | state.messages]

    state
    |> Map.put(:last_event, 0)
    |> Map.put(:lte_latency, -1)
    |> Map.put(:messages,  new_messages)
  end

  defp cause_event(state = %{lte_latency: -1}, :restore_lte) do
    delta_t = :os.system_time(:millisecond) - state.start_time
    new_messages = [%{delta_t: delta_t, message: "IP SLA PROBE 20 STATE UP - LTE RESTORED"} | state.messages]

    state
    |> Map.put(:last_event, 0)
    |> Map.put(:lte_latency, :rand.uniform(30) + 68)
    |> Map.put(:messages,  new_messages)
  end

  defp cause_event(state = %{t1_latency: -1}, :restore_t1) do
    delta_t = :os.system_time(:millisecond) - state.start_time
    new_messages = [%{delta_t: delta_t, message: "IP SLA PROBE 10 STATE UP - T1 RESTORED"} | state.messages]

    state
    |> Map.put(:last_event, 0)
    |> Map.put(:t1_latency, :rand.uniform(6) + 6)
    |> Map.put(:messages,  new_messages)
  end

  defp cause_event(state, _), do: state
end
