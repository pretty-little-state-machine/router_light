defmodule RouterLightFirmware.SNMPPoller do
  use GenServer

  alias RouterLightFirmware.StatusLight
  alias RouterLightFirmware.Utilities.SNMP
  alias RouterLightFirmware.Dashboard

  defstruct last_poll: %SNMP{},
            dashboard: %Dashboard{}

  # Milliseconds
  @polling_interval 300

  ####################
  # CLIENT API
  ####################
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :Poller)
  end

  def get_dashboard(pid) do
    GenServer.call(pid, :get_dashboard)
  end

  ####################
  # CALLBACKS
  ####################
  @impl true
  def init(:ok) do
    schedule_poll()
    {:ok, get_initial_state()}
  end

  @impl true
  def handle_call(:get_dashboard, _from, state) do
    {:reply, state.dashboard, state}
  end

  @impl true
  def handle_info(:poll, state) do
    cur_poll = SNMP.poll_batman()

    new_dashboard =
      Dashboard.update(state.dashboard, cur_poll, state.last_poll, @polling_interval)

    StatusLight.change_color(:StatusLight, new_dashboard.status_color)

    new_state =
      state
      |> Map.put(:dashboard, new_dashboard)
      |> Map.put(:last_poll, cur_poll)

    schedule_poll()
    {:noreply, new_state}
  end

  ####################
  # PRIVATE HELPERS
  ####################
  defp get_initial_state() do
    %__MODULE__{
      last_poll: %SNMP{},
      dashboard: Dashboard.get_initial_state()
    }
  end

  defp schedule_poll() do
    Process.send_after(self(), :poll, @polling_interval)
  end
end
