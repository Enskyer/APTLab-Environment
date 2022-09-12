#! /usr/bin/env bash

_SERVERURL=$1
_SERVERPORT=$2
_PEERS=$3
ADDITIONAL_ALLOWEDIPS=$4

install_wireguard() {
  echo "[$(date +%H:%M:%S)]: Installing stavhaygn/docker-wireguard-sample..."
  cd /opt
  git clone https://github.com/stavhaygn/docker-wireguard-sample.git wireguard
  cd /opt/wireguard
  source .wireguard.env

  SERVERURL=${_SERVERURL:-$SERVERURL}
  SERVERPORT=${_SERVERPORT:-$SERVERPORT}
  PEERS=${_PEERS:-$PEERS}
  if [ ! -z "$ADDITIONAL_ALLOWEDIPS" ]; then
    ADDITIONAL_ALLOWEDIPS=", $ADDITIONAL_ALLOWEDIPS"
  fi

  WIREGUARD_ENV="PUID=1000\nPGID=1000\nTZ=\"Asia/Taipei\"\nSERVERURL=\"$SERVERURL\"\nSERVERPORT=$SERVERPORT\nPEERS=$PEERS\nPEERDNS=\"8.8.8.8\"\nINTERNAL_SUBNET=\"10.13.13.0\"\nALLOWEDIPS=\"10.13.13.0/24$ADDITIONAL_ALLOWEDIPS\"" 
  echo -e $WIREGUARD_ENV | tee .wireguard.env
  docker compose up -d
  sleep 1

  i=0
  echo "-----------------------------------------------------------"
  for conf in /opt/wireguard/config/peer*/peer*.conf; do
    i=$((i+1))
    cat $conf | sed "s/\[Peer\]/[Peer$i]/g"
    echo "-----------------------------------------------------------"
  done
}

install_wireguard
