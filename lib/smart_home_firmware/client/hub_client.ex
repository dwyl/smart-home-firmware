defmodule SmartHomeFirmware.HubClient do
  @moduledoc """
  Communicates with the hub server and manages the
  Locks state.
  """
  use GenServer
  require Logger

  alias PhoenixClient.{Channel, Socket}


  def start_link(opts) do
    Logger.info("Hub service starting....")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    send(__MODULE__, :startup)
    {:ok, %{channel: nil}}
  end

  def handle_info(:startup, state) do
    wait_for_socket_available()
    {:ok, hostname} = :inet.gethostname()
    {:ok, response, channel} = Channel.join(Socket, "lock:" <> to_string(hostname))
    handle_handshake_resp(response)

    {:noreply, %{ state | channel: channel}}
  end

  defp handle_handshake_resp(body) do
    SmartHomeFirmware.Lock.setup(body)
  end

  defp wait_for_socket_available() do
    if !PhoenixClient.Socket.connected?(Socket) do
      Process.sleep(100)
      wait_for_socket_available()
    end
  end


end
