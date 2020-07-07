defmodule SmartHomeFirmwareTest do
  use ExUnit.Case
  doctest SmartHomeFirmware

  test "greets the world" do
    assert SmartHomeFirmware.hello() == :world
  end
end
