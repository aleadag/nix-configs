#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "This script requires root permission, please run with 'sudo'"
  exit 1
fi

rm /etc/systemd/system/nix-daemon.service.d/proxy-override.conf
systemctl daemon-reload
systemctl restart nix-daemon
