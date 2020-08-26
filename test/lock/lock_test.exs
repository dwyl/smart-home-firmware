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

    test "unlock unlocks for 10 seconds", %{lock: lock} do
      send(lock, :unlock)
      state = GenServer.call(lock, :fetch_state)
      assert 1 == Circuits.GPIO.read(state.relay_out)
    end

    test "end of timeout locks door", %{lock: lock} do
      send(lock, :timeout)
      state = GenServer.call(lock, :fetch_state)
      assert 0 = Circuits.GPIO.read(state.relay_out)
    end

    test "NFC read works (integration)", %{lock: lock} do
      send(lock, {:store_update, :lock, %{mode: 1}})
      assert :ok == SmartHomeFirmware.Lock.nfc_read("1234", lock)
    end

    test "NFC pair read works (integration)", %{lock: lock} do
      send(lock, {:store_update, :lock, %{mode: 3}})
      SmartHomeFirmware.State.put(:pair_params, %{test: :test})

      assert :ok == SmartHomeFirmware.Lock.nfc_read("1234", lock)
    end

    test "handles unimplemented mode", %{lock: lock} do
      send(lock, {:store_update, :lock, %{mode: -1}})
      assert :ok == SmartHomeFirmware.Lock.nfc_read("1234", lock)
    end

  end
end
