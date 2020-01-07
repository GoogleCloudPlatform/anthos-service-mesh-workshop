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

log() { echo "$1" >&2; }

WORKDIR="`pwd`"

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified}"
gcloud config set project $PROJECT_ID

CLUSTER_NAME="meshexp"
CLUSTER_ZONE="us-central1-a"
CTX="gke_${PROJECT_ID}_${CLUSTER_ZONE}_${CLUSTER_NAME}"


# istio version on both cluster and VM
ISTIO_VERSION=${ISTIO_VERSION:=1.4.2}

# VM
VM_ZONE="us-east1-b"
VM_NAME="productcatalogservice"
VM_PORT="3550"
VM_NAMESPACE="default"
VM_IMAGE="gcr.io/google-samples/microservices-demo/productcatalogservice:v0.1.3"





