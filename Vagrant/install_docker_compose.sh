#! /usr/bin/env bash

install_docker_compose() {
  echo "[$(date +%H:%M:%S)]: Installing Docker Compose..."
  curl -s -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  docker-compose -v
}

install_docker_compose
