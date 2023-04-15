#! /usr/bin/env bash

HOST_IP=${1:-"192.168.57.105"}
HELK_KIBANA_UI_PASSWORD=${2:-"As3gur@!"}
HELK_NEO4J_PASSWORD=${3:-"WGuch02g"}

install_APTLab_HELK() {
  echo "[$(date +%H:%M:%S)]: Installing APTLab-HELK..."
  export DEBIAN_FRONTEND=noninteractive 
  apt-get install -y apache2-utils
  cd /opt
  git clone https://github.com/Enskyer/APTLab-HELK.git
  cd /opt/APTLab-HELK/docker/ && ./helk_install.sh -p $HELK_KIBANA_UI_PASSWORD -n $HELK_NEO4J_PASSWORD -i $HOST_IP -b 'aptlab-helk-kibana-notebook-neo4j-analysis'
}

install_APTLab_HELK
