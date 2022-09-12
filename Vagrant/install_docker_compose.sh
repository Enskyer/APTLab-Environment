#! /usr/bin/env bash

install_docker_compose() {
  echo "[$(date +%H:%M:%S)]: Installing Docker Compose..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install docker-compose-plugin
  docker compose version
}

install_docker_compose
