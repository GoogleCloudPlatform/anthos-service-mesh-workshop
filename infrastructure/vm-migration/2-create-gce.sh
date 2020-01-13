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

# allow traffic from K8s cluster to VM service
export K8S_POD_CIDR=$(gcloud container clusters describe ${CLUSTER_NAME?} --zone ${CLUSTER_ZONE?} --format=json | jq -r '.clusterIpv4Cidr')

gcloud compute firewall-rules create ${CLUSTER_NAME}-to-${VM_NAME} \
--description="Allow k8s pods CIDR to istio-gce instance" \
--source-ranges=$K8S_POD_CIDR \
--target-tags=${VM_NAME} \
--action=ALLOW \
--rules=tcp:3550

# allow ssh to the VM
# gcloud compute firewall-rules create default-allow-ssh --allow tcp:22

gcloud compute --project=$PROJECT_ID instances create $VM_NAME --zone=$VM_ZONE \
--machine-type=n1-standard-2 --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE \
--image=ubuntu-1604-xenial-v20190628 --image-project=ubuntu-os-cloud --boot-disk-size=10GB \
--boot-disk-type=pd-standard --boot-disk-device-name=$VM_NAME --tags=${VM_NAME}

