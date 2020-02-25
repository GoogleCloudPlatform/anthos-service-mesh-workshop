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

# TASK: This script completes the deploy application section of ASM workshop.

#!/bin/bash

# Verify that the scripts are being run from Linux and not Mac
if [[ $OSTYPE != "linux-gnu" ]]; then
    echo "ERROR: This script and consecutive set up scripts have only been tested on Linux. Currently, only Linux (debian) is supported. Please run in Cloud Shell or in a VM running Linux".
    exit;
fi

# Export a SCRIPT_DIR var and make all links relative to SCRIPT_DIR
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")
export LAB_NAME=canary-deployment

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Canary Deployments

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
title_no_wait "*** Lab: Canary Deployments ***"
echo -e "\n"

# https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop/#9
title_and_wait "Run the repo_setup.sh script, to copy the baseline manifests into k8s-repo."
print_and_execute "export CANARY_DIR=\"${WORKDIR}/asm/k8s_manifests/prod/app-canary\""
print_and_execute "export K8S_REPO=\"${WORKDIR}/k8s-repo\""
echo "export CANARY_DIR=${WORKDIR}/asm/k8s_manifests/prod/app-canary" >> ~/.bashrc 
echo "export K8S_REPO=${WORKDIR}/k8s-repo" >> ~/.bashrc
print_and_execute "${CANARY_DIR}/repo-setup.sh"

title_no_wait "The following manifests are copied:"

title_no_wait "1. frontend-v2 deployment"
title_no_wait "2. frontend-v1 patch (to include the \"v1\" label, and an image with a \"/version\" endpoint)"
title_no_wait "3. respy, a small pod that will print HTTP response distribution, and help us visualize the canary deployment in real time."
title_no_wait "4. frontend Istio DestinationRule - splits the frontend Kubernetes Service into two subsets, v1 and v2, based on the \"version\" deployment label"
title_no_wait "5. frontend Istio VirtualService - routes 100% of traffic to frontend v1. This overrides the Kubernetes Service default round-robin behavior, which would immediately send 50% of all Dev1 regional traffic to frontend v2."
echo -e "\n"

title_and_wait "Commit changes to the k8s-repo."
print_and_execute "cd ${K8S_REPO}" 
print_and_execute "git add . && git commit -am \"frontend canary setup\""
print_and_execute "git push"
print_and_execute "cd ${CANARY_DIR}"

echo -e "\n"
title_no_wait "View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
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
title_no_wait "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}. \n Exiting...."
  exit 1
fi

title_and_wait "Wait until frontend, frontend-v2 and respy Deployments are Ready."
print_and_execute "is_deployment_ready ${DEV1_GKE_1} frontend frontend"
print_and_execute "is_deployment_ready ${DEV1_GKE_2} frontend frontend"
print_and_execute "is_deployment_ready ${DEV2_GKE_1} frontend frontend"
print_and_execute "is_deployment_ready ${DEV2_GKE_2} frontend frontend"
print_and_execute "is_deployment_ready ${DEV1_GKE_1} frontend frontend-v2"
print_and_execute "is_deployment_ready ${DEV1_GKE_2} frontend frontend-v2"
print_and_execute "is_deployment_ready ${DEV2_GKE_1} frontend frontend-v2"
print_and_execute "is_deployment_ready ${DEV2_GKE_2} frontend frontend-v2"
print_and_execute "is_deployment_ready ${DEV1_GKE_1} frontend respy"
print_and_execute "is_deployment_ready ${DEV2_GKE_1} frontend respy"

title_no_wait "Obtain the pod name for the respy pod."
print_and_execute "RESPY_POD=\$(kubectl --context ${DEV1_GKE_1} get pod -n frontend -l app=respy -o jsonpath='{..metadata.name}')"
print_and_execute "echo \${RESPY_POD}"

title_and_wait "Run the watch command to observe the HTTP response distribution for the frontend service. We can see that all traffic is going to the frontend v1 deployment, defined in the new VirtualService."
print_and_execute "export TMUX_SESSION=\$(tmux display-message -p '#S')"
if [[ -z ${TMUX_SESSION} ]]; then
    error_no_wait "failed to locate tmux session."
    error_no_wait "verify that you are running in cloud shell and are in a tmux session."
    exit 1
fi
print_and_execute "tmux split-window -d -t ${TMUX_SESSION}:0 -p33 -v \"export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh; kubectl --context ${DEV1_GKE_1} exec -n frontend -it $RESPY_POD -c respy /bin/sh -- -c 'watch -n 1 ./respy --u http://frontend:80/version --c 10 --n 500'; sleep 2\""

title_and_wait "Run the canary deployment script for the Dev1 region. Note - this script takes about 10 minutes to complete."
print_and_execute "K8S_REPO=${K8S_REPO} CANARY_DIR=${CANARY_DIR} OPS_DIR=${OPS_GKE_1_CLUSTER} OPS_CONTEXT=${OPS_GKE_1} ./auto-canary.sh"

# Close the split pane.
title_no_wait "Close the split pane."
print_and_execute "tmux respawn-pane -t ${TMUX_SESSION}:0.1 -k 'exit'"

title_no_wait "Obtain the pod name for the respy pod in the second cluster."
print_and_execute "RESPY_POD=\$(kubectl --context ${DEV2_GKE_1} get pod -n frontend -l app=respy -o jsonpath='{..metadata.name}')"
print_and_execute "echo \${RESPY_POD}"

cd ${CANARY_DIR}
title_and_wait "Run the watch command to observe the HTTP response distribution for the frontend service on the second cluster. We can see that all traffic is going to the frontend v1 deployment, defined in the new VirtualService."
print_and_execute "export TMUX_SESSION=\$(tmux display-message -p '#S')"
if [[ -z ${TMUX_SESSION} ]]; then
    error_no_wait "failed to locate tmux session."
    error_no_wait "verify that you are running in cloud shell and are in a tmux session."
    exit 1
fi
print_and_execute "tmux split-window -d -t ${TMUX_SESSION}:0 -p33 -v \"export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh; kubectl --context ${DEV2_GKE_1} exec -n frontend -it $RESPY_POD -c respy /bin/sh -- -c 'watch -n 1 ./respy --u http://frontend:80/version --c 10 --n 500'; sleep 10\""

title_and_wait "Run the canary deployment script for the Dev1 region. Note - this script takes about 10 minutes to complete."
print_and_execute "K8S_REPO=${K8S_REPO} CANARY_DIR=${CANARY_DIR} OPS_DIR=${OPS_GKE_2_CLUSTER} OPS_CONTEXT=${OPS_GKE_2} ./auto-canary.sh"

# Close the split pane.
title_no_wait "Close the split pane."
print_and_execute "tmux respawn-pane -t ${TMUX_SESSION}:0.1 -k 'exit'"

echo -e "\n"
title_no_wait "Congratulations! You have successfully completed the Canary Deployment lab."
echo -e "\n"
