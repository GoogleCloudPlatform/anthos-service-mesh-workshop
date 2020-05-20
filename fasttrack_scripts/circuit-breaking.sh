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

# TASK: This script completes the deploy application section of ASM workshop.

#!/bin/bash

# Verify that the scripts are being run from Linux and not Mac
if [[ $OSTYPE != "linux-gnu" ]]; then
    echo "ERROR: This script and consecutive set up scripts have only been tested on Linux. Currently, only Linux (debian) is supported. Please run in Cloud Shell or in a VM running Linux".
    exit;
fi

# Export a SCRIPT_DIR var and make all links relative to SCRIPT_DIR
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")
export LAB_NAME=circuit-breaking

# Create a logs folder and file and send stdout and stderr to console and log file
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Circuit Breaking

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
echo "${bold}*** Lab: Circuit Breaking ***${normal}"
echo -e "\n"


# https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop/#12
print_and_execute "export K8S_REPO=${WORKDIR}/k8s-repo; export ASM=${WORKDIR}/asm"

title_no_wait "⚡️ Here is the circuit breaker Destination Rule for shipping service:"
print_and_execute "cat $ASM/k8s_manifests/prod/istio-networking/app-shipping-circuit-breaker.yaml"

echo -e "\n"
title_and_wait "Copy the Destination Rule into both Ops clusters..."
print_and_execute "cp $ASM/k8s_manifests/prod/istio-networking/app-shipping-circuit-breaker.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/app-shipping-circuit-breaker.yaml"
print_and_execute "cp $ASM/k8s_manifests/prod/istio-networking/app-shipping-circuit-breaker.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/app-shipping-circuit-breaker.yaml"
print_and_execute "cd ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/; kustomize edit add resource app-shipping-circuit-breaker.yaml"
print_and_execute "cd ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/; kustomize edit add resource app-shipping-circuit-breaker.yaml"


# Copy Fortio pod to test circuit breaker
title_and_wait "Copy the Fortio loadgen pod into one of the Dev clusters..."
print_and_execute "cp $ASM/k8s_manifests/prod/app/deployments/app-fortio.yaml ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/"
print_and_execute "cd ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments; kustomize edit add resource app-fortio.yaml"


# Push to k8s-repo master
title_and_wait "⬆️ Commit changes to the k8s-repo."
print_and_execute "cd ${K8S_REPO}"
print_and_execute "git add . && git commit -am \"circuit breaker setup - shippingservice\""
print_and_execute "git push"


# Wait for ops cloud build to complete
echo -e "\n"
title_no_wait "🛑 View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
title_no_wait "Waiting for Cloud Build to finish..."


BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
while [[ "${BUILD_STATUS}" =~ WORKING|QUEUED ]]; do
    title_no_wait "Still waiting for cloud build to finish. Sleep for 10s"
    sleep 10
    BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
done

echo -e "\n"
title_no_wait "✅ Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "⚠️ Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}. \n Exiting...."
  exit 1
fi


# Exec into fortio pod - send requests 1 concurrent connection (all requests should succeed)
title_no_wait "🚀 Use the fortio loadgen to send 1000 requests to shipping service - 1 concurrent connection."
title_and_wait "Because we set our circuit breaker's MaxPendingRequests to 1, all requests should succeed..."
print_and_execute "FORTIO_POD=$(kubectl --context ${DEV1_GKE_1} get pod -n shipping | grep fortio | awk '{ print $1 }')"
print_and_execute "kubectl --context ${DEV1_GKE_1} exec -it $FORTIO_POD -n shipping -c fortio -- /usr/bin/fortio load -grpc -c 1 -n 1000 -qps 0 shippingservice.shipping.svc.cluster.local:50051"


# Exec into fortio pod - send requests with 2 concurrent connections (about 2/3 of requests should fail)
title_no_wait "🚀 Use the fortio loadgen to send 1000 requests to shipping service - 2 concurrent connections"
title_and_wait "😱 Now we are tripping the circuit breaker. About a third of these requests should fail..."
print_and_execute  "kubectl --context ${DEV1_GKE_1} exec -it $FORTIO_POD -n shipping -c fortio -- /usr/bin/fortio load -grpc -c 2 -n 1000 -qps 0 shippingservice.shipping.svc.cluster.local:50051"


# Get envoy metrics ("upstream pending overflow")
title_and_wait "📈 Get envoy metrics for shippingservice - upstream pending overflow"
print_and_execute  "kubectl --context ${DEV1_GKE_1} exec -it $FORTIO_POD -n shipping -c istio-proxy  -- sh -c 'curl localhost:15000/stats' | grep shipping | grep pending"


# Remove destinationrule from both repos
title_and_wait "🧹 Cleanup - remove circuit breaker DestinationRule for shipping service"
print_and_execute "kubectl --context ${OPS_GKE_1} delete destinationrule shippingservice-circuit-breaker -n shipping"
print_and_execute "rm ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/app-shipping-circuit-breaker.yaml"
print_and_execute "cd ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/; kustomize edit remove resource app-shipping-circuit-breaker.yaml"
print_and_execute "kubectl --context ${OPS_GKE_2} delete destinationrule shippingservice-circuit-breaker -n shipping"
print_and_execute "rm ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/app-shipping-circuit-breaker.yaml"
print_and_execute "cd ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/; kustomize edit remove resource app-shipping-circuit-breaker.yaml"


# Push to master
title_and_wait "⬆️ Commit changes to the k8s-repo."
print_and_execute "cd ${K8S_REPO}"
print_and_execute "git add . && git commit -am \"circuit breaker cleanup\""
print_and_execute "git push"


echo -e "\n"
title_no_wait "✅ Congratulations! You have successfully completed the Circuit Breaking lab. ⚡️"
echo -e "\n"



