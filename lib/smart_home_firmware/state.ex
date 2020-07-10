defmodule SmartHomeFirmware.State do
  @moduledoc """
  Single source of truth for the state of the device.

  Wrapper around a GenServer that controls state and dispatching
  """

  alias SmartHomeFirmware.State.Manager

  @initial_state %{
    name: "Uninitialzed Device",
    uuid: nil,
    mode: 0
  }

  def start_link(_opts) do
    SmartHomeFirmware.State.Supervisor.start_link(initial_state: @initial_state)
  end

  def child_spec(_opts) do
    SmartHomeFirmware.State.Supervisor.child_spec(initial_state: @initial_state)
  end

  def subscribe(key) do
    Registry.register(SmartHomeFirmware.Registry, :state_registry, key)
  end

  def unsubscribe() do
    Registry.unregister(SmartHomeFirmware.Registry, :state_registry)
  end

  def get(key) do
    Manager.get(key)
  end

  def put(key, val) do
    Manager.put(key, val)
  end
end
