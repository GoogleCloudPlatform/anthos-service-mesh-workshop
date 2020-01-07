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

export GCE_IP=$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances describe ${SVC_NAME} --zone=${ZONE})
"kubectl -n ${VM_SERVICE_NAMESPACE} apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: ${VM_SERVICE_NAME}
spec:
  hosts:
  - ${VM_SERVICE_NAME}.${VM_SERVICE_NAMESPACE}.svc.cluster.local
  ports:
  - number: ${VM_SERVICE_PORT}
    name: grpc
    protocol: GRPC
  resolution: STATIC
  endpoints:
  - address: ${GCE_IP}
    ports:
      grpc: ${VM_SERVICE_PORT}
    labels:
      app: ${VM_SERVICE_NAME}
EOF"

# generate selector-less service / Endpoint
istioctl register -n ${VM_SERVICE_NAMESPACE} productcatalogservice ${GCE_IP} grpc:${VM_SERVICE_PORT} --labels version=vm

# deploy hipstershop - all services except productcatalog - to GKE cluster
kubectl apply -f manifests/hipstershop.yaml