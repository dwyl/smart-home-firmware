<div align="center">

# Smart Home Firmware

## Very much a Work-in-Progress 🚧

[![Build Status](https://img.shields.io/travis/com/dwyl/smart-home-firmware/master.svg?style=flat-square)](https://travis-ci.com/dwyl/smart-home-firmware)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/smart-home-firmware/master.svg?style=flat-square)](http://codecov.io/github/dwyl/smart-home-firmware?branch=master)

</div>

The firmware that runs on the Raspberry Pis for https://github.com/dwyl/smart-home-security-system

## Setup

### 1. Connect your Raspberry Pi to the PN532 development board.
We're using UART to connect to the board, so connect the pins up as follows:

[GPIO Diagram](https://pinout.xyz/pinout/uart)

| Pi           | PN532 |
|--------------|-------|
5v             | 5v
Ground         | Ground
TXD (GPIO 14)  | RX
RXD (GPIO 15)  | TX

### 2. Clone this repository

```
git clone https://github.com/dwyl/smart-home-firmware
```

### 3. Build the firmware and burn it to an SD card

For the firmware to compile you will need a few build dependencies installed,
please see: https://github.com/dwyl/learn-scenic#installing

#### 3.1 set environment variables
```
export MIX_TARGET=<tag> # see dwyl/learn-nerves
export NERVES_NETWORK_SSID=<Wifi network name> #  Optional, if you want WiFi connection
export NERVES_NETWORK_PSK=<Wifi password> # again, optional
```

#### 3.2 Build & burn firmware
Insert and SD card to your host
```
mix firmware.burn
```

#### 4. Deploy
Insert SD card into Raspberry pi, turn it on then SSH in
```
ssh nerves.local
```

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
