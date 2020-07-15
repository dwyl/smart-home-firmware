defmodule SmartHomeFirmwareTest.State do
  use ExUnit.Case, async: true

  alias SmartHomeFirmware.State
  alias SmartHomeFirmware.State.Manager

  # Just test the state module to make sure state works well
  # Not testing the integration through the rest of the app.

  describe "manager" do
    setup %{test: test} do
      {:ok, _pid} = start_supervised({State, name: test})

      %{state: test}
    end

    test "initial state is correct", %{state: state} do
      state = State.Manager.get(state, :lock)

      assert state.name == "Uninitialized Device"
    end

    test "put and get", %{state: state} do
      Manager.put(state, :lock, "test_val")
      new_state = Manager.get(state, :lock)

      assert new_state == "test_val"
    end

    test "subscribe", %{state: state} do
      Manager.subscribe(state, :test_key)
      Manager.put(state, :test_key, "new val")

      assert_receive {:store_update, :test_key, "new val"}
    end

    test "unsubscribe", %{state: state} do
      Manager.subscribe(state, :test_key)
      Manager.unsubscribe(state)

      Manager.put(state, :test_key, "new_val")

      refute_receive {:store_update, :test_key, "new val"}, 20

    end
  end
end
