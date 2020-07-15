defmodule SmartHomeFirmware.State.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    unless !is_nil(Keyword.get(opts, :name)) do
      raise ArgumentError, "Please give a name!"
    end

    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    name = Keyword.get(opts, :name)
    registry_name = registry_name(name)

    children = [
      {SmartHomeFirmware.State.Manager, {name, registry_name, opts}},
      {Registry, [keys: :duplicate, name: registry_name]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def registry_name(name) do
    Module.concat(State.Registry, name)
  end
end
