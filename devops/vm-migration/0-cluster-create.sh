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

# TODO - remove

source ./env.sh

gcloud container clusters create $CLUSTER_NAME --zone $CLUSTER_ZONE --username "admin" \
--machine-type "n1-standard-4" --image-type "COS" --disk-size "100" \
--num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --no-enable-autoupgrade

gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE
kubectl config use-context $CTX