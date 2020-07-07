defmodule SmartHomeFirmware.HubClient do
  use GenServer
  require Logger

  @host Application.fetch_env!(:smart_home_firmware, :hub)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    case HTTPoison.get(@host <> "/handshake") do
      {:ok, _data} ->
        Logger.info("Found hub!")
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error(inspect reason)
    end

    {:ok, %{}}
  end

end
