defmodule SmartHomeFirmware.FeatureSupervisor do
  use DynamicSupervisor


  @moduledoc """
  This supervisor allows us to dynamically toggle on and off features of
  the firmware.
  """

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
