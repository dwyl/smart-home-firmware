defmodule SmartHomeFirmware.MifareClientImplementation do
  use Nerves.IO.PN532.MifareClient

  def setup(pid, _state) do
    Logger.info("NFC Reader starting....")
  end

  def handle_event(:card_detected, _card = %{tg: _target_number, sens_res: _sens_res, sel_res: _sel_res, nfcid: identifier}) do
    identifier
    |> Base.encode16()
    |> SmartHomeFirmware.Lock.nfc_read()
  end

  def handle_event(:card_lost, _card = %{tg: _target_number, sens_res: _sens_res, sel_res: _sel_res, nfcid: identifier}) do
    Logger.info("Lost connection with Mifare card with ID: #{Base.encode16(identifier)}")
  end
end
