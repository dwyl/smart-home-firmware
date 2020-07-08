defmodule SmartHomeFirmware.Lock do
@moduledoc """
Controls the lock itself and manages state
"""
use GenServer
require Logger

@default_state %{
  type: 1,
  uuid: "",
  name: "Unconfigured lock"
}

def start_link(opts) do
  GenServer.start_link(__MODULE__, opts, name: __MODULE__)
end

def init(_opts) do
  {:ok, @default_state}
end

def setup(opts) do
  GenServer.cast(__MODULE__, {:setup, opts})
end

def handle_cast({:setup, params}, state) do
  Logger.info("Configuring lock with params: #{inspect params}")
  {:noreply, Map.merge(params, state)}
end
end
