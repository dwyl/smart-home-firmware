import Config

config :smart_home_firmware, :viewport, %{
  name: :main_viewport,
  default_scene: {SmartHomeFirmware.Display.Scene.Welcome},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :smart_home_firmware"]
    }
  ]
}
