#! /usr/bin/env bash

PUBLIC_IP=$1
NETMASK=${2:-"255.255.255.0"}
GATEWAY=$3

fix_eth2_to_public_ip() {
  if [ ! -z "$PUBLIC_IP" ]; then
    ETH2_IP=$(ip -4 addr show eth2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ "$ETH2_IP" != "$PUBLIC_IP" ]; then
      ip addr add "$PUBLIC_IP"/"$NETMASK" brd + dev eth2
      ip link set eth2 up
      ip route del default
      ip route add default via "$GATEWAY" dev eth2
    fi
  fi
}

fix_eth2_to_public_ip
