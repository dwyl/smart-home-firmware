defmodule SmartHomeFirmware.State.Manager do
  use GenServer

  require Logger

  def start_link({name, _registry, _opts} = args) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init({_name, registry, opts}) do
    init_state = Keyword.fetch!(opts, :initial_state)
    state = %{private: %{registry: registry}, store: init_state}
    {:ok, state}
  end

  def get(state, key) do
    GenServer.call(state, {:get, key})
  end

  def put(state, key, val) do
    GenServer.cast(state, {:put, key, val})
  end

  def subscribe(name, key) do
    SmartHomeFirmware.State.Supervisor.registry_name(name)
    |> Registry.register(:state_registry, key)
  end

  def unsubscribe(name) do
    SmartHomeFirmware.State.Supervisor.registry_name(name)
    |> Registry.unregister(:state_registry)
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
        dispatch(state, key, val)

        {:noreply, Map.replace!(state, :store, updated_store)}
    end
  end

  defp dispatch(state, key, val) do
    msg = {:store_update, key, val}

    Registry.match(state.private.registry, :state_registry, key)
    |> Enum.each(fn {pid, _match} -> send(pid, msg) end)
  end
end
