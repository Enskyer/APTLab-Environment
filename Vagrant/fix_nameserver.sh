#! /usr/bin/env bash

fix_nameserver() {
  for ip in "127.0.0.53" "192.168.57.1"; do
    if grep $ip /etc/resolv.conf; then
      sed -i "s/nameserver $ip/nameserver 8.8.8.8/g" /etc/resolv.conf
      chattr +i /etc/resolv.conf
      break
    fi
  done
}

fix_nameserver
