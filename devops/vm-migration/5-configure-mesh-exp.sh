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
kubectl config use-context $CTX
mkdir -p vm/

ISTIO_SERVICE_CIDR=$(gcloud container clusters describe ${CLUSTER_NAME?} \
                       --zone ${CLUSTER_ZONE?} --project ${PROJECT_ID?} \
                       --format "value(servicesIpv4Cidr)")
echo $ISTIO_SERVICE_CIDR

log "istio CIDR is: ${ISTIO_SERVICE_CIDR}"

echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" | tee ./vm/cluster.env
echo "ISTIO_INBOUND_PORTS=${VM_PORT},8080" >> ./vm/cluster.env


# Get istio control plane certs
kubectl -n ${VM_NAMESPACE?} get secret istio.default \
  -o jsonpath='{.data.root-cert\.pem}' | base64 --decode | tee ./vm/root-cert.pem
kubectl -n ${VM_NAMESPACE?} get secret istio.default \
  -o jsonpath='{.data.key\.pem}' | base64 --decode | tee ./vm/key.pem
kubectl -n ${VM_NAMESPACE?} get secret istio.default \
  -o jsonpath='{.data.cert-chain\.pem}' | base64 --decode | tee ./vm/cert-chain.pem

log "sending cluster.env, certs, and script to VM..."
gcloud compute --project ${PROJECT_ID?} scp --zone ${VM_ZONE?} ./vm/* ./run-on-vm.sh ${VM_NAME?}:
log "...done."
