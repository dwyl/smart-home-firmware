#!/bin/sh

git clone https://github.com/dwyl/smart-home-auth-server
cd smart-home-auth-server

mix setup
mix phx.server &

cd ../