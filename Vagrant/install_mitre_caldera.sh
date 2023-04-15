#! /usr/bin/env bash

install_mitre_caldera() {
  echo "[$(date +%H:%M:%S)]: Installing Enskyer/mitre-caldera..."
  cd /opt
  git clone https://github.com/Enskyer/caldera.git --recursive --branch 4.1.0.20230328
  cd /opt/mitre-caldera
  docker compose up -d --build
  # Need to up again, because the caldera has some problems when it up for the first time
  docker compose down
  docker compose up -d
}

install_mitre_caldera
