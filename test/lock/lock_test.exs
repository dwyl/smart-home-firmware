defmodule SmartHomeFirmwareTest.LockTest do
  use ExUnit.Case, async: true

  describe "lock" do
    setup %{test: test} do
      {:ok, lock} = start_supervised({SmartHomeFirmware.Lock, name: test})

      %{lock: lock}
    end

    test "updates state", %{lock: lock} do
      send(lock, {:store_update, :lock, %{val: "test_val"}}) # mock subscribe call
      state = GenServer.call(lock, :fetch_state)
      assert state.val == "test_val"
    end
  end
end
