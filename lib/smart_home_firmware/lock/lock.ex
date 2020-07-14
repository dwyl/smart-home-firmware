defmodule SmartHomeFirmware.Lock do
  @moduledoc """
  Controls the lock itself and manages state
  """
  use GenServer
  require Logger

  alias SmartHomeFirmware.HubClient

  @modes %{
    internal: 1,
    external: 2,
    pair: 3
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
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

  def do_pairing(opts) do
    Logger.info("Putting lock in pairing mode...")
    GenServer.cast(__MODULE__, {:pair, opts})
  end

  def nfc_read(identifier) do
    GenServer.cast(__MODULE__, {:nfc_read, identifier})
  end

  def handle_cast({:pair, params}, state) do
    state =
      state
      |> Map.replace!(:mode, @modes.pair)
      |> Map.put(:pair_params, params)

    Logger.info(inspect(state))
    {:noreply, state}
  end

  def handle_cast({:nfc_read, identifier}, %{mode: 3} = state) do
    state
    |> Map.get(:pair_params)
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
