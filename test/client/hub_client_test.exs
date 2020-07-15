defmodule SmartHomeFirmwareTest.HubClientTest do
  use ExUnit.Case

  alias SmartHomeFirmware.HubClient

  # Mock some stuff
  defmodule FakeEncoder do
    @behaviour Phoenix.Channels.GenSocketClient.Serializer

    def decode_message(msg), do: msg
    def encode_message(msg), do: msg
  end

  defmodule FakeTransport do
    @behaviour Phoenix.Channels.GenSocketClient.Transport
    def start_link(_url, _opts), do: {:ok, self()}
    def push(_pid, frame) do
      send(self(), {:frame, frame})
      :ok
    end
  end

  describe "client" do

    test "correct callback returned" do
      assert {
        :connect,
        _url,
        _data,
        _state
      } = HubClient.init([])
    end


  end
end
