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
GCE_IP=$(gcloud compute instances describe $VM_NAME --zone $VM_ZONE --format=text  | grep '^networkInterfaces\[[0-9]\+\]\.networkIP:' | sed 's/^.* //g' 2>&1)
log "$VM_NAME's IP is $GCE_IP"


kubectl config use-context $CTX

# register VM with GKE istio
./istio-${ISTIO_VERSION}/bin/istioctl register $VM_NAME $GCE_IP "grpc:${VM_PORT}"

# output result of registration
kubectl get endpoints $VM_NAME -o yaml

# add a ServiceEntry for ProductCatalog
kubectl apply -n default -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: ${VM_NAME}
spec:
  hosts:
  - ${VM_NAME}.${VM_NAMESPACE}.svc.cluster.local
  location: MESH_INTERNAL
  ports:
  - number: ${VM_PORT}
    name: grpc
    protocol: GRPC
  resolution: STATIC
  endpoints:
  - address: ${GCE_IP}
    ports:
      grpc: ${VM_PORT}
    labels:
      app: ${VM_NAME}
EOF
