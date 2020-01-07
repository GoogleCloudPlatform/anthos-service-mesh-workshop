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
GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

gcloud compute ssh --zone $VM_ZONE $VM_NAME -- "GWIP=${GWIP} ISTIO_VERSION=${ISTIO_VERSION} VM_IMAGE=${VM_IMAGE} VM_NAME=${VM_NAME} VM_PORT=${VM_PORT} ./run-on-vm.sh"
