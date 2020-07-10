defmodule SmartHomeFirmware.State.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    unless !is_nil(Keyword.get(opts, :initial_state)) do
      raise ArgumentError, "expected initial state, got: #{inspect opts}"
    end

    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      {SmartHomeFirmware.State.Manager, opts},
      {Registry, [keys: :duplicate, name: SmartHomeFirmware.Registry]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
