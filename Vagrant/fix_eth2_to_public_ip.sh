#! /usr/bin/env bash

PUBLIC_IP=$1
NETMASK=${2:-"255.255.255.0"}

fix_eth2_to_public_ip() {
  if [ ! -z "$PUBLIC_IP" ]; then
    ETH2_IP=$(ip -4 addr show eth2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ "$ETH2_IP" != "$PUBLIC_IP" ]; then
      ip addr flush dev eth2
      ip addr add "$PUBLIC_IP"/"$NETMASK" brd + dev eth2
    fi
  fi
}

fix_eth2_to_public_ip
