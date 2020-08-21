defmodule SmartHomeFirmwareTest.HubClientTest do
  use ExUnit.Case, async: true
  require Logger

  alias SmartHomeFirmware.HubClient

  @state %{
    "mode" => "0",
    "uuid" => "0",
    "name" => "test",
    "feature_flags" => [],

  }

  # Mock some stuff
  defmodule FakeEncoder do
    @behaviour Phoenix.Channels.GenSocketClient.Serializer

    def decode_message(msg), do: msg
    def encode_message(msg), do: {:ok, msg}
  end

  defmodule FakeTransport do
    @behaviour Phoenix.Channels.GenSocketClient.Transport
    def start_link(_url, _opts), do: {:ok, self()}
    def push(pid, frame) do
      send(self(), {:frame, frame})
      :ok
    end
  end

  test "correct callback returned" do
    assert {
      :connect,
      _url,
      _data,
      _state
    } = HubClient.init([])
  end

  test "corrrect send pair call" do
    HubClient.send_pair(:test, self())
    assert_received {:pair, :test}
  end

  test "send correct event call" do
    HubClient.send_event(:test, self())
    assert_received {:event_out, :test}
  end

  test "verify_access returns" do
    f = spawn(fn -> send(self(), HubClient.verify_access(:test_device, 123, self())) end)

    send(f, %{access: :true})
  end

  test "send correct reset_state call" do
    HubClient.reset_state(self())
    assert_received :reset_state
  end

  describe "client" do
    setup %{test: test} do
      opts = [
        name: test,
        connect_callback: self()
      ]

      pid = start_supervised!({SmartHomeFirmware.HubClient, opts})

      receive do
        :connected ->
          :ok
        after
          2_000 ->
            raise "Could not connect to hub"
      end


      # Mock the transport map
      transport = %{
        transport_mod: SmartHomeFirmwareTest.HubClientTest.FakeTransport,
        transport_pid: self(),
        serializer: SmartHomeFirmwareTest.HubClientTest.FakeEncoder
      }

      %{client: pid, transport: transport, test: test}
    end

    # Test callbacks

    test "handle_connected inserts channel", %{transport: transport} do
      result = HubClient.handle_connected(transport, %{})
      assert result == {:ok, %{
        :channel => HubClient.get_channel()
      }}
    end

    test "handle_join updates state", %{transport: transport} do
      SmartHomeFirmware.State.subscribe(:self)

      {:ok, %{}} =
        HubClient.handle_joined("lock:test", @state, transport, %{connect_callback: :none})

      assert_receive {:store_update, :self, %{name: "test"}}
    end

    test "handle_message - mode:pair updates lock state", %{transport: transport} do
      SmartHomeFirmware.State.subscribe(:pair_params)
      payload = %{test: :val}

      HubClient.handle_message("", "mode:pair", payload, transport, %{})

      assert_receive {:store_update, :pair_params, payload}
    end

    test "handle_message event pushes to display", %{transport: transport} do
      SmartHomeFirmware.State.subscribe(:display)
      payload = %{"message" => :test}

      HubClient.handle_message("", "event", payload, transport, %{})

      assert_receive {:store_update, :display, :test}
    end

    test ":connect sends a connect respone", %{transport: transport} do
      assert {:connect, %{}} ==
        HubClient.handle_info(:connect, transport, %{})
    end

    test "handle_reply {reset_reply} resets state", %{transport: transport} do
      SmartHomeFirmware.State.subscribe(:self)
      state =
        @state
        |> Map.put("name", "reset")

      HubClient.handle_reply("", 1, %{"response" => state}, transport, %{reset_reply: 1})

      assert_receive {:store_update, :self, payload}
    end

    test "handle_reply {verify_access} returns correct value", %{transport: transport} do
      HubClient.handle_reply("", 1, %{"response" =>
        %{"user" => :me, "access" => true}},
        transport,
        %{verify_access_reply: {1, self()}}
      )

      assert_receive(%{user: :me, access: true})
    end

    test "test verify_access works (integration)", %{client: client} do
      {:ok, uuid} =
        SmartHomeFirmware.State.get(:lock)
        |> Map.fetch(:uuid)

      result = HubClient.verify_access("1234", uuid, client)

      assert %{access: false} = result
    end

    test "sending event works (integration)", %{client: client} do
      assert {:event_out, %{}} = HubClient.send_event(%{event: "test"}, client)
    end

    test "handle_disconnect gracefully (integration)", %{client: client} do
      # Check our disconnect handling does not error...
      Phoenix.Channels.GenSocketClient.notify_disconnected(client, :test)
    end

    test "reset_state successfully asks for new state (integration)", %{client: client} do
      HubClient.reset_state(client)
    end

    test "joining a channel is successful", %{client: client} do
      send(client, :join)
    end
  end
end
