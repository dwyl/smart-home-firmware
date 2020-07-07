defmodule SmartHomeFirmware.NFC do

  alias SmartHomeFirmware.MifareClientImplementation

  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts) do
    Logger.info("Attempting to start...")
    with {:ok, pid} <- MifareClientImplementation.start_link(),
         :ok <- MifareClientImplementation.open(pid, "ttyS0"),
         :ok <- MifareClientImplementation.start_target_detection(pid) do
      {:ok, pid}
    end
  end
end
