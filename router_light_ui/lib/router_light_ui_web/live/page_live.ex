defmodule RouterLightUiWeb.PageLive do
  use RouterLightUiWeb, :live_view

  alias RouterLightFirmware.SNMPPoller

  @update_interval 333

  @impl true
  def mount(_params, _session, socket) do
    send(self(), {:update_dashboard, %{}})
    {:ok, assign(socket, %{})}
  end

  @impl true
  def handle_info({:update_dashboard, _state}, socket) do
    dashboard = SNMPPoller.get_dashboard(:Poller)

    Process.sleep(@update_interval)
    send(self(), {:update_dashboard, %{}})
    {:noreply, socket |> push_event("dashboard", dashboard)}
  end

end
