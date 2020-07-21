defmodule SmartHomeFirmware.Display.Scene.Welcome do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives
  import Scenic.Components

  @graph Graph.build()
  |> text("Hello World!", font_size: 22, translate: {20, 80})

  def init(_scene_args, _opts) do
    {:ok, @graph, push: @graph}
  end
end
