import Config

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :logger, level: :info

config :smart_home_firmware,
  hub: "192.168.0.14:4000"

config :shoehorn,
  init: [:nerves_runtime, :nerves_pack],
  app: Mix.Project.config()[:app]

# Nerves Runtime can enumerate hardware devices and send notifications via
# SystemRegistry. This slows down startup and not many programs make use of
# this feature.

config :nerves_runtime, :kernel, use_system_registry: false

# Erlinit can be configured without a rootfs_overlay. See
# https://github.com/nerves-project/erlinit/ for more information on
# configuring erlinit.

config :nerves,
  erlinit: [
    hostname_pattern: "lock-%s"
  ]

# Authorize the device to receive firmware using your public key.
# See https://hexdocs.pm/nerves_firmware_ssh/readme.html for more information
# on configuring nerves_firmware_ssh.

keys =
  [
    Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
  ]
  |> Enum.filter(&File.exists?/1)

if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
    """)

config :nerves_firmware_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)


key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "wpa_psk"
# Configure the network using vintage_net
# See https://github.com/nerves-networking/vintage_net for more information
config :vintage_net,
  regulatory_domain: "GB",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
     {"wlan0",
     %{
       type: VintageNetWiFi,
       vintage_net_wifi: %{
         key_mgmt: String.to_atom(key_mgmt),
         ssid: System.get_env("NERVES_NETWORK_SSID"),
         psk: System.get_env("NERVES_NETWORK_PSK")
       },
       ipv4: %{method: :dhcp}
     }}
  ]

config :mdns_lite,
  # The `host` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For our system, this
  # is "lock-<4 digit serial#>.local".  mdns_lite also advertises
  # "nerves.local" for convenience. If more than one Nerves device is on the
  # network, delete "nerves" from the list.

  host: [:hostname],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      name: "SSH Remote Login Protocol",
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      name: "Secure File Transfer Protocol over SSH",
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      name: "Erlang Port Mapper Daemon",
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    }
  ]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

if Mix.target() == :rpi3 do
  import_config "#{Mix.target()}.exs"
end
