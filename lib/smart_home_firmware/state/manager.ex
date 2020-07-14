defmodule SmartHomeFirmware.State.Manager do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    init_state = Keyword.fetch!(opts, :initial_state)
    state = %{_private: %{}, store: %{lock: init_state}}
    {:ok, state}
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, val) do
    GenServer.cast(__MODULE__, {:put, key, val})
  end

  def handle_call({:get, key}, _caller, %{store: store} = state) do
    val = Map.get(store, key)

    {:reply, val, state}
  end

  def handle_cast({:put, key, val}, %{store: store} = state) do
    case Map.get(store, key) do
      ^val ->
        :ok
        {:noreply, state}
      _ ->
        updated_store = Map.put(store, key, val)
        dispatch(key, val)

        {:noreply, Map.replace!(state, :store, updated_store)}
    end
  end

  defp dispatch(key, val) do
    msg = {:store_update, key, val}

    Registry.match(SmartHomeFirmware.Registry, :state_registry, key)
    |> Enum.each(fn {pid, _match} -> send(pid, msg) end)
  end
end
