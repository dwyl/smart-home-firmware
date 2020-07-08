defmodule SmartHomeFirmware.NetworkSupervisor do
  @moduledoc """
  Contains all the processes that should only be
  started once there is a working network connection

  I don't know if this is still needed now we're using sockets

  TODO: Supervisor fails on restart
  """

  use DynamicSupervisor
  require Logger

  @host Application.fetch_env!(:smart_home_firmware, :hub)
  @socket_ops [
    url: "ws://#{@host}/socket/websocket",
    params: %{
      name: "test"
    }
  ]

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
    # started once a LAN connection is availiable.
    [

      {PhoenixClient.Socket, {@socket_ops, name: PhoenixClient.Socket}},
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
        VintageNet.subscribe(["connection"]) # Getting rid of this warning will be nice

        receive do
          change ->
            Logger.info(inspect(change))
            start()
        end

    end
  end
end
