defmodule SmartHomeFirmware.State do
  @moduledoc """
  Single source of truth for the state of the device.

  Wrapper around a GenServer that controls state and dispatching
  """

  alias SmartHomeFirmware.State.Manager

  @initial_state %{
    lock: %{
      name: "Uninitialized Device",
      uuid: nil,
      mode: 0
    }
  }

  def start_link(opts) do
    [initial_state: @initial_state]
    |> Keyword.merge(opts)
    |> SmartHomeFirmware.State.Supervisor.start_link()
  end

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, SmartHomeFirmware.State),
      start: {SmartHomeFirmware.State, :start_link, [opts]},
      type: :supervisor
    }
  end

  def subscribe(key) do
    Manager.subscribe(SmartHomeFirmware, key)
  end

  def unsubscribe(_key) do
    Manager.unsubscribe(SmartHomeFirmware)
  end

  def get(key) do
    Manager.get(SmartHomeFirmware, key)
  end

  def put(key, val) do
    Manager.put(SmartHomeFirmware, key, val)
  end
end
