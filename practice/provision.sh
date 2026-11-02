#!/bin/bash
# Install Docker, kubectl and k3d in VM (called by vagrant up)
set -e
 
apt-get update
apt-get install -y curl ca-certificates
 
# Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker vagrant
 
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl
 
# k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
 
echo "Docker, kubectl and k3d have been installed."
 