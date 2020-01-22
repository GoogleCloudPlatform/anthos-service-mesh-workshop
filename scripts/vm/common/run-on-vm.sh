#!/bin/bash

# THIS SCRIPT RUNS ON THE VM
set -euo pipefail
log() { echo "$1" >&2; }

export ISTIO_VERSION="1.4.2"

log "🐋 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable";
sudo apt-get update;
sudo apt-get install -y docker-ce;

log "⛵️ Installing Istio ${ISTIO_VERSION}..."
curl -L https://storage.googleapis.com/istio-release/releases/${ISTIO_VERSION}/deb/istio-sidecar.deb > istio-sidecar.deb
sudo dpkg -i istio-sidecar.deb
echo "${GWIP} istio-citadel istio-pilot istio-pilot.istio-system" | sudo tee -a /etc/hosts
sudo mkdir -p /etc/certs
sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
sudo cp cluster.env /var/lib/istio/envoy
sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy


log "🚀 Starting Istio..."
sudo systemctl start istio-auth-node-agent
sudo systemctl start istio