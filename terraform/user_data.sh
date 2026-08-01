#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Bootstrap started at $(date) ==="

echo "=== Updating apt packages ==="
apt-get update -y
apt-get upgrade -y

echo "=== Installing prerequisites ==="
apt-get install -y \
  curl \
  git \
  conntrack \
  ca-certificates \
  apt-transport-https \
  gnupg \
  lsb-release

echo "=== Installing Docker Engine ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Enabling Docker service ==="
systemctl enable docker
systemctl start docker

echo "=== Granting ubuntu user Docker permissions ==="
usermod -aG docker ubuntu

echo "=== Installing kubectl ==="
curl -fsSL "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

echo "=== Installing Minikube ==="
curl -fsSL "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64" -o /usr/local/bin/minikube
chmod +x /usr/local/bin/minikube

echo "=== Starting Minikube as ubuntu user ==="
sudo -u ubuntu -H bash -c 'minikube start --driver=docker'

echo "=== Bootstrap completed at $(date) ==="