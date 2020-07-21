defmodule SmartHomeFirmware.FeatureManager do
  @moduledoc """
  Manages what features are currently enabled and which ones aren't.
  """
  require Logger

  # Feature flags allow certain processes to be turned on and off.
  # Here we define the flags and associated modules
  @feature_flags [
    lock: SmartHomeFirmware.Lock,
    display: SmartHomeFirmware.Display
  ]

  use GenServer

  alias SmartHomeFirmware.FeatureSupervisor

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    SmartHomeFirmware.State.subscribe(:self)
    {:ok, %{}}
  end

  def handle_info({:store_update, :self, %{feature_flags: flags}}, state) do
    # flags are stored as strings, we need to convert them to atoms
    flags
    |> Enum.map(&String.to_existing_atom(&1))
    |> enable_features()

    {:noreply, state}
  end

  @doc """
  enable_features takes a list of features and enables them on the firmware.

  E.g. [:lock, :display]
  """
  def enable_features(features) do
    Logger.info(inspect features)
    features
    |> Enum.map(&Keyword.get(@feature_flags, &1))
    |> Enum.each(&DynamicSupervisor.start_child(FeatureSupervisor, &1))
  end
end
