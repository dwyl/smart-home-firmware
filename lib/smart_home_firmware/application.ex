defmodule SmartHomeFirmware.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @host Application.fetch_env!(:smart_home_firmware, :hub)

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SmartHomeFirmware.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: SmartHomeFirmware.Worker.start_link(arg)
        # {SmartHomeFirmware.Worker, arg},
        #
        # Don't add stuff here that needs a Network connection!
        # Add it in `NetworkSupervisor`
        {SmartHomeFirmware.State, name: SmartHomeFirmware},
        {PhoenixClient.Socket, {get_socket_opts(), name: PhoenixClient.Socket}},
        SmartHomeFirmware.Lock,
        SmartHomeFirmware.HubClient
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: SmartHomeFirmware.Worker.start_link(arg)
      # {SmartHomeFirmware.Worker, arg},
    ]
  end

  def children(_target) do
    [
      SmartHomeFirmware.NFC
      # Children for all targets except host
      # Starts a worker by calling: SmartHomeFirmware.Worker.start_link(arg)
      # {SmartHomeFirmware.Worker, arg},
    ]
  end

  def get_socket_opts() do
    {:ok, hostname} = :inet.gethostname()
    [
      url: "ws://#{@host}/socket/websocket",
      reconnect_interval: 15_000,
      params: %{
        name: to_string(hostname)
      }
    ]
  end

  def target() do
    Application.get_env(:smart_home_firmware, :target)
  end
end
