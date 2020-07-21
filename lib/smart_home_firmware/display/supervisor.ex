defmodule SmartHomeFirmware.Display do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    main_viewport_config = Application.get_env(:smart_home_firmware, :viewport)
    children = [
      {Scenic, viewports: [main_viewport_config]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
