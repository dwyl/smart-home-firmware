defmodule SmartHomeFirmware.Lock do
  @moduledoc """
  Controls the lock itself and manages state
  """
  use GenServer
  require Logger

  alias SmartHomeFirmware.HubClient

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    Logger.info("Starting lock controller...")
    state = SmartHomeFirmware.State.get(:lock)
    SmartHomeFirmware.State.subscribe(:lock)
    {:ok, state}
  end

  def handle_info({:store_update, :lock, val}, state) do
    Logger.info("State: lock updated to: #{inspect val}")
    {:noreply, Map.merge(state, val)}
  end

  def setup(opts) do
    GenServer.cast(__MODULE__, {:setup, opts})
  end

  def nfc_read(identifier) do
    GenServer.cast(__MODULE__, {:nfc_read, identifier})
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
    HubClient.send_event("Got access: #{inspect resp.user["email"]}: #{resp.access}")

    {:noreply, state}
  end

  def handle_cast({:nfc_read, _}, %{mode: mode} = state) do
    Logger.info("Unimplemented mode: #{inspect mode}/Lock not configured")

    {:noreply, state}
  end
end
