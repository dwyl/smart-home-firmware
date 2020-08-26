defmodule SmartHomeFirmware.Lock do
  @moduledoc """
  Controls the lock itself and manages state
  """
  use GenServer
  require Logger

  @unlock_time 10_000

  alias SmartHomeFirmware.HubClient

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    Logger.info("Starting lock controller...")
    {:ok, gpio} = Circuits.GPIO.open(4, :output)
    state =
      SmartHomeFirmware.State.get(:lock)
      |> Map.put(:relay_out, gpio)


    SmartHomeFirmware.State.subscribe(:lock)
    {:ok, state}
  end

  def handle_info({:store_update, :lock, val}, state) do
    Logger.info("State: lock updated to: #{inspect val}")
    {:noreply, Map.merge(state, val)}
  end

  def handle_info(:unlock, state) do
    Circuits.GPIO.write(state.relay_out, 1)
    {:noreply, state, @unlock_time}
  end

  def handle_info(:timeout, state) do
    Circuits.GPIO.write(state.relay_out, 0)
    {:noreply, state}
  end

  def setup(opts) do
    GenServer.cast(__MODULE__, {:setup, opts})
  end

  def nfc_read(identifier, pid \\ __MODULE__) do
    GenServer.cast(pid, {:nfc_read, identifier})
  end

  def handle_cast({:nfc_read, identifier}, %{mode: 3} = state) do
    SmartHomeFirmware.State.get(:pair_params)
    |> Map.put("serial", identifier)
    |> HubClient.send_pair()

    HubClient.reset_state()

    {:noreply, state}
  end

  def handle_cast({:nfc_read, identifier}, %{mode: 1, uuid: uuid} = state) do
    resp = HubClient.verify_access(identifier, uuid)
    Logger.info("Got access: #{inspect resp}")
    case resp.access do
      true ->
        HubClient.send_event(%{access: true, user: resp.user})
        send(self(), :unlock)
      _ ->
        HubClient.send_event(%{access: false})
    end

    {:noreply, state}
  end

  def handle_cast({:nfc_read, _}, %{mode: mode} = state) do
    Logger.info("Unimplemented mode: #{inspect mode}/Lock not configured")

    {:noreply, state}
  end

  # Get genserver state for testing.
  def handle_call(:fetch_state, _from, state) do

    {:reply, state, state}
  end
end
