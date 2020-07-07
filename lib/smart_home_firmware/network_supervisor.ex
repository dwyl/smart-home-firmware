defmodule SmartHomeFirmware.NetworkSupervisor do
  @moduledoc """
  Contains all the processes that should only be
  started once there is a working network connection
  """

  use DynamicSupervisor
  require Logger

  def start_link(opts) do
    spawn(__MODULE__, :wait_for_internet, [])
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start() do
    # Add modules that need a network connection here and they'll be
    # started once a LAN connection is availiable
    [
      SmartHomeFirmware.HubClient
    ]
    |> Enum.each(
      &DynamicSupervisor.start_child(__MODULE__, &1)
    )
  end
  def wait_for_internet() do
    Logger.info("Waiting for internet....")
    case Application.get_env(:smart_home_firmware, :target) do
      :host ->
        # We presume the host has internet
        start()
      _target ->
        Logger.info("Waiting for vintagenet")
        VintageNet.subscribe(["connection"])

        receive do
          {VintageNet, ["connection"], _old_state, :lan, _metadata} ->
            start()
        end

    end
  end
end
