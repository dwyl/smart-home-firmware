defmodule SmartHomeFirmwareTest.HubClientTest do
  use ExUnit.Case # No async due to some race conditions
  require Logger

  alias SmartHomeFirmware.HubClient

  # Mock some stuff
  defmodule FakeEncoder do
    @behaviour Phoenix.Channels.GenSocketClient.Serializer

    def decode_message(msg), do: msg
    def encode_message(msg), do: {:ok, msg}
  end

  defmodule FakeTransport do
    @behaviour Phoenix.Channels.GenSocketClient.Transport
    def start_link(_url, _opts), do: {:ok, self()}
    def push(_pid, frame) do
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
        transport: SmartHomeFirmwareTest.HubClientTest.FakeTransport,
        socket_opts: [
          serializer: SmartHomeFirmwareTest.HubClientTest.FakeEncoder
        ]
      ]

      pid = start_supervised!({SmartHomeFirmware.HubClient, opts})

      # Mock the transport map
      transport = %{
        transport_mod: SmartHomeFirmwareTest.HubClientTest.FakeTransport,
        transport_pid: self(),
        serializer: SmartHomeFirmwareTest.HubClientTest.FakeEncoder
      }

      %{client: pid, transport: transport}
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
        HubClient.handle_joined("lock:test", %{
          "mode" => "0",
          "uuid" => "0",
          "name" => "test",
          "feature_flags" => []
        }, transport, %{})

      assert_receive {:store_update, :self, %{name: "test"}}
    end

    test "handle_message - mode:pair updates lock state", %{transport: transport} do
      SmartHomeFirmware.State.subscribe(:pair_params)
      payload = %{test: :val}

      HubClient.handle_message("", "mode:pair", payload, transport, %{})

      assert_receive {:store_update, :pair_params, payload}
    end
  end
end
