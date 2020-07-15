defmodule SmartHomeFirmwareTest do
  use ExUnit.Case
  doctest SmartHomeFirmware

  # Integration tests for application

  test "default state initialized" do
    state = SmartHomeFirmware.State.get(:lock)

    assert state.name == "Uninitialized Device"
  end

  test "can put state" do
    SmartHomeFirmware.State.put(:test, :test_val)

    assert SmartHomeFirmware.State.get(:test) == :test_val
  end

  test "can subscribe to state" do
    SmartHomeFirmware.State.subscribe(:test)
    SmartHomeFirmware.State.put(:test, :test_val)

    assert_receive {:store_update, :test, :test_val}, 20
  end

  test "can unsubscribe to state" do
    SmartHomeFirmware.State.unsubscribe(:test)
    SmartHomeFirmware.State.put(:test, :new_val)

    refute_receive {:store_update, :test, :new_val}, 20
  end
end
