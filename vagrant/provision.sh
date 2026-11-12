#!/usr/bin/env bash
set -e

ROLE="$1" # server or agent

install -D -m 644 /tmp/k3s-config.yaml /etc/rancher/k3s/config.yaml

mkdir -p /etc/rancher/k3s/config.yaml.d
echo "node-ip: $NODE_IP" > /etc/rancher/k3s/config.yaml.d/10-node.yaml
if [ "$ROLE" = "agent" ]; then
    echo "server: https://$SERVER_IP:6443" >> /etc/rancher/k3s/config.yaml.d/10-node.yaml
fi

case "$ROLE" in
    server)
        curl -fsSL https://get.k3s.io | sh -s - server
        ;;
    agent)
        curl -fsSL https://get.k3s.io | sh -s - agent
        ;;
    *)
        echo "Usage: provision.sh server|agent" >&2
        exit 1
        ;;
esac