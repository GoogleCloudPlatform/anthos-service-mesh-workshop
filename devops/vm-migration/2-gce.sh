#!/usr/bin/env bash

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

source ./env.sh

gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE
kubectl config use-context $CTX

mkdir -p vm/
export GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "GWIP is ${GWIP}"

# create cluster.env
ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID --format "value(servicesIpv4Cidr)")
echo "ISTIO service cidr is ${ISTIO_SERVICE_CIDR}"
echo -e "ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > vm/cluster.env
echo "ISTIO_INBOUND_PORTS=${VM_PORT}" >> vm/cluster.env

# create certs
kubectl -n $VM_NAMESPACE get secret istio.default  \
-o jsonpath='{.data.root-cert\.pem}' |base64 --decode > vm/root-cert.pem
kubectl -n $VM_NAMESPACE get secret istio.default  \
-o jsonpath='{.data.key\.pem}' |base64 --decode > vm/key.pem
kubectl -n $VM_NAMESPACE get secret istio.default  \
-o jsonpath='{.data.cert-chain\.pem}' |base64 --decode > vm/cert-chain.pem

# send over cluster env + certs
gcloud compute scp --project=${PROJECT_ID} --zone=${VM_ZONE} {./run-on-vm.sh,vm/key.pem,vm/cert-chain.pem,vm/cluster.env,vm/root-cert.pem} ${VM_NAME}:~

# install Docker and Istio remote in the VM, then run productcatalog as a container
# gcloud compute ssh --zone $VM_ZONE $VM_NAME -- "GWIP=${GWIP} ISTIO_VERSION=${ISTIO_VERSION} VM_IMAGE=${VM_IMAGE} VM_NAME=${VM_NAME} VM_PORT=${VM_PORT} ./run-on-vm.sh"