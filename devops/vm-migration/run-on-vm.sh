#!/bin/bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable";
sudo apt-get update;
sudo apt-get install -y docker-ce;

# add ingressgateway IP to /etc/hosts
echo "${GWIP} istio-citadel istio-pilot istio-pilot.istio-system" | sudo tee -a /etc/hosts

# install istio sidecar and node agent
curl -L https://storage.googleapis.com/istio-release/releases/${ISTIO_VERSION}/deb/istio-sidecar.deb > istio-sidecar.deb
sudo dpkg -i istio-sidecar.deb
sudo mkdir -p /etc/certs
sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
sudo cp cluster.env /var/lib/istio/envoy
sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy

sudo systemctl start istio-auth-node-agent
sudo systemctl start istio

sudo docker run -d --name ${VM_NAME} -p ${VM_PORT}:${VM_PORT} $VM_IMAGE


# run productcatalog service
sudo docker run -d -p 3550:3550 gcr.io/google-samples/microservices-demo/productcatalogservice:v0.1.3