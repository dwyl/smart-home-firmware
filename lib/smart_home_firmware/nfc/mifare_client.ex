defmodule SmartHomeFirmware.MifareClientImplementation do
  use Nerves.IO.PN532.MifareClient

  def setup(pid, _state) do
    Logger.info("Client init with pid #{inspect pid}")
  end

  def handle_event(:card_detected, _card = %{tg: target_number, sens_res: sens_res, sel_res: sel_res, nfcid: identifier}) do

    Logger.info("Detected new Mifare card with ID: #{Base.encode16(identifier)}")
  end

  def handle_event(:card_lost, _card = %{tg: target_number, sens_res: sens_res, sel_res: sel_res, nfcid: identifier}) do
    Logger.info("Lost connection with Mifare card with ID: #{Base.encode16(identifier)}")
  end
end
