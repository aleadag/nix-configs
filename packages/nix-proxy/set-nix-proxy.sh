#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <proxy>"
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  echo "This script requires root permission, please run with 'sudo'"
  exit 1
fi

PROXY=$1

mkdir -p /etc/systemd/system/nix-daemon.service.d/
cat <<EOF >/etc/systemd/system/nix-daemon.service.d/proxy-override.conf
[Service]
Environment="http_proxy=$PROXY"
Environment="https_proxy=$PROXY"
Environment="all_proxy=$PROXY"
EOF
systemctl daemon-reload
systemctl restart nix-daemon
