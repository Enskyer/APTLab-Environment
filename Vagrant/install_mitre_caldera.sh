#! /usr/bin/env bash

install_mitre_caldera() {
  echo "[$(date +%H:%M:%S)]: Installing stavhaygn/mitre-caldera..."
  cd /opt
  git clone https://github.com/stavhaygn/mitre-caldera.git --recursive --branch 4.0.0.20220421-beta
  cd /opt/mitre-caldera
  docker-compose up -d --build
  # Need to up again, because the caldera has some problems when it up for the first time
  docker-compose down
  docker-compose up -d
}

install_mitre_caldera
