defmodule SmartHomeFirmware.HubClient do
  @moduledoc """
  Communicates with the hub server and manages the
  Locks state.
  """
  use GenServer
  require Logger

  alias PhoenixClient.{Channel, Socket, Message}


  def start_link(opts) do
    Logger.info("Hub service starting....")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    send(__MODULE__, :startup)
    {:ok, %{channel: nil}}
  end

  def send_pair(pair) do
    GenServer.cast(__MODULE__, {:pair, pair})
  end

  def reset_state() do
    GenServer.cast(__MODULE__, :reset_state)
  end

  def handle_info(:startup, state) do
    wait_for_socket_available()
    {:ok, hostname} = :inet.gethostname()
    {:ok, response, channel} = Channel.join(Socket, "lock:" <> to_string(hostname))
    handle_handshake_resp(response)

    {:noreply, %{ state | channel: channel}}
  end

  def handle_info(%Message{event: "mode:pair", payload: payload}, state) do
    SmartHomeFirmware.Lock.do_pairing(payload)
    {:noreply, state}
  end

  def handle_info(%Message{event: event}) do
    Logger.info("Received uncrecognised event: #{event}")
  end

  def handle_cast({:pair, pair_data}, state) do
    Channel.push(state.channel, "pair:complete", pair_data)

    {:noreply, state}
  end

  def handle_cast(:reset_state, state) do
    {:ok, reset} = Channel.push(state.channel, "reset", %{})

    handle_handshake_resp(reset)

    {:noreply, state}
  end

  defp handle_handshake_resp(body) do
    SmartHomeFirmware.Lock.setup(%{
      mode: body["mode"],
      uuid: body["uuid"],
      name: body["name"]
    })
  end

  defp wait_for_socket_available() do
    if !PhoenixClient.Socket.connected?(Socket) do
      Process.sleep(100)
      wait_for_socket_available()
    end
  end

end
