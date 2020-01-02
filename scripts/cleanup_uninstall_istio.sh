#!/usr/bin/env bash

# Copyright 2019 Google LLC
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

# TASK: Uninstall Istio from all clusters

source ./vars/vars.sh

kubectl --context ${OPS_GKE_1} delete -f ./k8s-repo/${OPS_GKE_1_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml
kubectl --context ${OPS_GKE_2} delete -f ./k8s-repo/${OPS_GKE_2_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml

rm ./k8s-repo/${OPS_GKE_1_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml
rm ./k8s-repo/${OPS_GKE_2_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml

kubectl --context ${DEV1_GKE_1} delete -f ./k8s-repo/${DEV1_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
kubectl --context ${DEV1_GKE_2} delete -f ./k8s-repo/${DEV1_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
kubectl --context ${DEV2_GKE_1} delete -f ./k8s-repo/${DEV2_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml
kubectl --context ${DEV2_GKE_2} delete -f ./k8s-repo/${DEV2_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml

rm ./k8s-repo/${DEV1_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
rm ./k8s-repo/${DEV1_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
rm ./k8s-repo/${DEV2_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml
rm ./k8s-repo/${DEV2_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml 

cd ./k8s-repo
git add . && git commit -am "deleted istio"
git push google master
cd ..

