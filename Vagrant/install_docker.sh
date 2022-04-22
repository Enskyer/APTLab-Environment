#! /usr/bin/env bash

install_docker() {
  echo "[$(date +%H:%M:%S)]: Installing Docker..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get -qq update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  usermod -aG docker vagrant
  docker -v
}

install_docker
