import Config

config :smart_home_firmware, :viewport, %{
  name: :main_viewport,
  # default_scene: {NervesScenic.Scene.Crosshair, nil},
  default_scene: {SmartHomeFirmware.Display.Scene.Welcome, nil},
  size: {1920, 1080},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
  ]
}
