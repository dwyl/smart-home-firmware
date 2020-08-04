defmodule SmartHomeFirmwareTest.HubClientTest do
  use ExUnit.Case, async: true
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

      %{client: pid}
    end

  end
end
