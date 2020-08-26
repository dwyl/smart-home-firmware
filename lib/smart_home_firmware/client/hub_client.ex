defmodule SmartHomeFirmware.HubClient do
  @moduledoc """
  Communicates with the hub server and manages the
  Locks state.
  """
  require Logger
  alias Phoenix.Channels.GenSocketClient

  @behaviour GenSocketClient

  @host Application.fetch_env!(:smart_home_firmware, :hub)
  @modes %{
    internal: 1,
    external: 2,
    pair: 3
  }

  def send_pair(pair, pid \\ __MODULE__) do
    send(pid, {:pair, pair})
  end

  def send_event(event, pid \\ __MODULE__) do
    send(pid, {:event_out, event})
  end

  def verify_access(device_id, uuid, pid \\ __MODULE__) do
    send(pid, {:verify_access, {device_id, uuid, self()}})

    # Hack on a syncronous response
    receive do
      resp = %{access: _result} ->
        resp
    end

  end

  def reset_state(pid \\ __MODULE__) do
    send(pid, :reset_state)
  end

  def start_link(opts) do
    Logger.info("Hub service starting....")
    name = Keyword.get(opts, :name, __MODULE__)
    transport = Keyword.get(opts, :transport,  Phoenix.Channels.GenSocketClient.Transport.WebSocketClient)
    socket_opts = Keyword.get(opts, :socket_opts, [])

    GenSocketClient.start_link(
      __MODULE__,
      transport,
      opts, # arbitary argument
      socket_opts, # socket opts
      name: name # GenServer opts
    )
  end

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    %{
      id: name,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def init(opts) do
    {url, name} = get_socket_opts()
    connect_callback = Keyword.get(opts, :connect_callback, :none)

    {:connect, url, [{"name", name}],
      %{first_join: true, ping_ref: 1, connect_callback: connect_callback}}
  end

  def handle_connected(transport, state) do
    Logger.info("Connected to hub")
    channel = get_channel()
    GenSocketClient.join(transport, channel)

    {:ok, Map.put(state, :channel, channel)}
  end

  def handle_disconnected(reason, state) do
    Logger.warn("disconnected: #{inspect reason}")
    Process.send_after(self(), :connect, :timer.seconds(1))

    {:ok, state}
  end

  def handle_joined("lock:" <> _lock_serial, payload, _transport, state) do
    handle_handshake_resp(payload)
    fire_connect_callback(state.connect_callback)
    {:ok, state}
  end

  def handle_message(_topic, "mode:pair", payload, _transport, state) do
    store = SmartHomeFirmware.State.get(:lock)
    |> Map.replace!(:mode, @modes.pair)

    SmartHomeFirmware.State.put(:lock, store)
    SmartHomeFirmware.State.put(:pair_params, payload)
    {:ok, state}
  end

  def handle_message(_topic, "event", payload, _transport, state) do

    SmartHomeFirmware.State.put(:display, payload["message"])

    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    {:connect, state}
  end

  def handle_info({:pair, pair_data}, transport, state) do
    {:ok, _ref} = GenSocketClient.push(transport, state.channel, "pair:complete", pair_data)

    {:ok, state}
  end

  def handle_info(:reset_state, transport, state) do
    {:ok, ref} = GenSocketClient.push(transport, state.channel, "reset", %{})

    {:ok, Map.put(state, :reset_reply, ref)}
  end

  def handle_info({:event_out, event}, transport, state) do
    Logger.info("Client: Pushing new event: #{inspect event}")
    push = GenSocketClient.push(transport, state.channel, "event", event)

    case push do
      {:ok, _ref} -> {:ok, state}

      {:error, reason} ->
        Logger.info(inspect reason)
        {:ok, state}
    end
  end

  def handle_info({:verify_access, {device, uuid, pid}}, transport, state) do
    {:ok, ref} = GenSocketClient.push(
      transport, state.channel, "access:request",
      %{
        uuid: uuid,
        device: device
    })
    {:ok, Map.put(state, :verify_access_reply, {ref, pid})}
  end

  def handle_info(:join, transport, state) do
    case GenSocketClient.join(transport, get_channel()) do
      {:error, _reason} ->
        Process.send_after(self(), :join, 5000)
      {:ok, _ref} -> :ok
    end

    {:ok, state}
  end

  def handle_reply(_topic, ref, %{"response" => payload}, _transport,
    %{reset_reply: ref} = state) do

    handle_handshake_resp(payload)
    {:ok, %{state | reset_reply: nil}}
  end

  def handle_reply(_topic, ref, %{"response"  => payload}, _transport,
    %{verify_access_reply: {ref, pid}} = state) do

    %{"user" => user, "access" => access} = payload
    send(pid, %{user: user, access: access})

    {:ok, %{state | verify_access_reply: nil}}
  end

  def handle_reply(_topic, _ref, %{"status" => "ok"}, _transport, state) do
    # We like okay replies :)
    {:ok, state}
  end

  defp handle_handshake_resp(body) do
    # TODO: Adapt backend to modularize this more -
    # I don't like having to split this out here.
    SmartHomeFirmware.State.put(:lock, %{
      mode: body["mode"],
      uuid: body["uuid"],
    })

    SmartHomeFirmware.State.put(:self, %{
      name: body["name"],
      feature_flags: body["feature_flags"]
    })
  end

  # Error handlers:
  def handle_join_error(topic, payload, _transport, state) do
    Logger.warn("Could not join #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_channel_closed(topic, _payload, _transport, state) do
    Logger.warn("Channel #{topic} closed...")
    Process.send_after(self(), :join, 5000)

    {:ok, Map.put(state, :channel, nil)}
  end

  def handle_call(_message, _from, _transport, state) do
    # Stub method to implement behaviour
    {:noreply, state}
  end

  def get_channel() do
    {:ok, hostname} = :inet.gethostname()

    "lock:" <> to_string(hostname)
  end

  defp get_socket_opts() do
    {:ok, hostname} = :inet.gethostname()
    scheme = get_scheme()
    {"#{scheme}://#{@host}/socket/websocket", to_string(hostname)}
  end

  defp get_scheme() do
    if Application.fetch_env!(:smart_home_firmware, :ssl) do
      "wss"
    else
      "ws"
    end
  end

  # Useful for testing and waiting for connections
  defp fire_connect_callback(pid) when is_pid(pid) do
    send(pid, :connected)
  end

  defp fire_connect_callback(:none) do
    :ok
  end

end
