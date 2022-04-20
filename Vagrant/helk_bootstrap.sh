#! /usr/bin/env bash

# This is the script that is used to provision the APTLab-HELK host
HOST_IP="192.168.57.105"
HELK_USER="vagrant"
HELK_KIBANA_UI_PASSWORD="As3gur@!"
HELK_NEO4J_PASSWORD="WGuch02g"

# Override existing DNS Settings using netplan, but don't do it for Terraform AWS builds
if ! curl -s 169.254.169.254 --connect-timeout 2 >/dev/null; then
  echo -e "    eth1:\n      dhcp4: true\n      nameservers:\n        addresses: [8.8.8.8,8.8.4.4]" >>/etc/netplan/01-netcfg.yaml
  netplan apply
fi

if grep '127.0.0.53' /etc/resolv.conf; then
  sed -i 's/nameserver 127.0.0.53/nameserver 8.8.8.8/g' /etc/resolv.conf && chattr +i /etc/resolv.conf
fi

export DEBIAN_FRONTEND=noninteractive
echo "apt-fast apt-fast/maxdownloads string 10" | debconf-set-selections
echo "apt-fast apt-fast/dlflag boolean true" | debconf-set-selections

if ! grep 'mirrors.ubuntu.com/mirrors.txt' /etc/apt/sources.list; then
  sed -i "2ideb mirror://mirrors.ubuntu.com/mirrors.txt focal main restricted universe multiverse\ndeb mirror://mirrors.ubuntu.com/mirrors.txt focal-updates main restricted universe multiverse\ndeb mirror://mirrors.ubuntu.com/mirrors.txt focal-backports main restricted universe multiverse\ndeb mirror://mirrors.ubuntu.com/mirrors.txt focal-security main restricted universe multiverse" /etc/apt/sources.list
fi

apt_install_prerequisites() {
  echo "[$(date +%H:%M:%S)]: Adding apt repositories..."
  # Add repository for apt-fast
  add-apt-repository -y -n ppa:apt-fast/stable 
  # Install prerequisites and useful tools
  echo "[$(date +%H:%M:%S)]: Running apt-get clean..."
  apt-get clean
  echo "[$(date +%H:%M:%S)]: Running apt-get update..."
  apt-get -qq update
  echo "[$(date +%H:%M:%S)]: Installing apt-fast..."
  apt-get -qq install -y apt-fast
  echo "[$(date +%H:%M:%S)]: Using apt-fast to install packages..."
  apt-fast install -y git ca-certificates curl gnupg lsb-release apache2-utils
}

test_prerequisites() {
  for package in git ca-certificates curl gnupg lsb-release apache2-utils; do
    echo "[$(date +%H:%M:%S)]: [TEST] Validating that $package is correctly installed..."
    # Loop through each package using dpkg
    if ! dpkg -S $package >/dev/null; then
      # If which returns a non-zero return code, try to re-install the package
      echo "[-] $package was not found. Attempting to reinstall."
      apt-get -qq update && apt-get install -y $package
      if ! which $package >/dev/null; then
        # If the reinstall fails, give up
        echo "[X] Unable to install $package even after a retry. Exiting."
        exit 1
      fi
    else
      echo "[+] $package was successfully installed!"
    fi
  done
}

fix_eth1_static_ip() {
  USING_KVM=$(lsmod | grep kvm)
  if [ -n "$USING_KVM" ]; then
    echo "[*] Using KVM, no need to fix DHCP for eth1 iface"
    return 0
  fi
  if [ -f /sys/class/net/eth2/address ]; then
    if [ "$(cat /sys/class/net/eth2/address)" == "00:50:56:a3:b1:c4" ]; then
      echo "[*] Using ESXi, no need to change anything"
      return 0
    fi
  fi
  # There's a fun issue where dhclient keeps messing with eth1 despite the fact
  # that eth1 has a static IP set. We workaround this by setting a static DHCP lease.
  if ! grep 'interface "eth1"' /etc/dhcp/dhclient.conf; then
    echo -e 'interface "eth1" {
      send host-name = gethostname();
      send dhcp-requested-address $HOST_IP;
    }' >>/etc/dhcp/dhclient.conf
    netplan apply
  fi

  # Fix eth1 if the IP isn't set correctly
  ETH1_IP=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
  if [ "$ETH1_IP" != "$HOST_IP" ]; then
    echo "Incorrect IP Address settings detected. Attempting to fix."
    ip link set dev eth1 down
    ip addr flush dev eth1
    ip link set dev eth1 up
    ETH1_IP=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ "$ETH1_IP" == "$HOST_IP" ]; then
      echo "[$(date +%H:%M:%S)]: The static IP has been fixed and set to $HOST_IP"
    else
      echo "[$(date +%H:%M:%S)]: Failed to fix the broken static IP for eth1. Exiting because this will cause problems with other VMs."
      exit 1
    fi
  fi

  # Make sure we do have a DNS resolution
  while true; do
    if [ "$(dig +short @8.8.8.8 github.com)" ]; then break; fi
    sleep 1
  done
}

install_docker() {
  echo "[$(date +%H:%M:%S)]: Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get -qq update
  apt-fast install -y docker-ce docker-ce-cli containerd.io
  docker -v
}

install_docker_compose() {
  echo "[$(date +%H:%M:%S)]: Downloading docker-compose..."
  curl -s -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  usermod -aG docker $HELK_USER
  docker-compose -v
}

install_APTLab_HELK() {
  echo "[$(date +%H:%M:%S)]: Installing APTLab-HELK..."
  cd /opt
  git clone https://github.com/stavhaygn/APTLab-HELK.git
  cd /opt/APTLab-HELK/docker/ && ./helk_install.sh -p $HELK_KIBANA_UI_PASSWORD -n $HELK_NEO4J_PASSWORD -i $HOST_IP -b 'aptlab-helk-kibana-notebook-neo4j-analysis'
}

main() {
  apt_install_prerequisites
  test_prerequisites
  fix_eth1_static_ip
  install_docker
  install_docker_compose
  install_APTLab_HELK
}

# Allow custom modes via CLI args
if [ -n "$1" ]; then
  eval "$1"
else
  main
fi
exit 0
