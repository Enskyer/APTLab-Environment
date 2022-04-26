#! /usr/bin/env bash

set_iptables_to_deny_eth2() {
  echo "[$(date +%H:%M:%S)]: Installing iptables..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y iptables

  echo "[$(date +%H:%M:%S)]: Setting iptables to drop packages from eth2(public)..."
  iptables -I INPUT -i eth2 -j DROP
}

set_iptables_to_deny_eth2
