defmodule SmartHomeFirmware.Display.Scene.Welcome do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives
  import Scenic.Components


  @message_time 5_000 # 5 seconds

  @image_path :code.priv_dir(:smart_home_firmware)
              |> Path.join("images/dwyl.png")

  @image_hash Scenic.Cache.Hash.file!(@image_path, :sha)

  @header "dwyl Home."
  @instruction_locked "Please scan your card/device"


  @graph Graph.build()
         |> group(
           fn g ->
             g
             |> rect({40, 40}, fill: {:image, @image_hash})
             |> text(@header, font_size: 72, id: :header, t: {40, 0})
           end,
           t: {40, 80}
         )
         |> text(@instruction_locked, font_size: 36, id: :instruction_text, t: {10, 160})

  def init(_scene_args, _opts) do
    Scenic.Cache.Static.Texture.load(@image_path, @image_hash)
    SmartHomeFirmware.State.subscribe(:display)
    {:ok, @graph, push: @graph}
  end

  def handle_info({:store_update, :display, %{"access" => true, "user" => user}}, graph) do
    new_graph = Graph.modify(graph, :instruction_text,
      &text(&1, "Welcome to home #{user["email"]}"))

    {:noreply, new_graph, [timeout: @message_time, push: new_graph]}
  end

  def handle_info({:store_update, :display, %{"access" => false}}, graph) do
    new_graph = Graph.modify(graph, :instruction_text,
      &text(&1, "Your access has been denied, please contact an admin"))

    {:noreply, new_graph, [timeout: @message_time, push: new_graph]}
  end

  # Always make sure to reset back to default.
  def handle_info(:timeout, graph) do
    graph = Graph.modify(graph, :instruction_text,
      &text(&1, @instruction_locked))

    SmartHomeFirmware.State.put(:display, nil)
    {:noreply, graph, push: graph}
  end

  def handle_info(_unhandled, graph) do
    {:noreply, graph}
  end
end
