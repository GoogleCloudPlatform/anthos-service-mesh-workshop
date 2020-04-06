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
export LAB_NAME=infrastructure-setup-user-workflow

# Create a logs folder and file and send stdout and stderr to console and log file
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Infrastructure Setup - User Workflow

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
title_no_wait "*** Lab: Infrastructure Setup - User Workflow ***"
echo -e "\n"

# https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop/#4
title_and_wait "Download kustomize cli and pv tools."
nopv_and_execute "mkdir -p ${HOME}/bin && cd ${HOME}/bin"
export KUSTOMIZE_FILEPATH="${HOME}/bin/kustomize"
if [ -f ${KUSTOMIZE_FILEPATH} ]; then
    title_no_wait "kustomize is already installed and in the ${KUSTOMIZE_FILEPATH} folder."
else
    nopv_and_execute "curl -s \"https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh\"  | bash"
fi
export PATH=$PATH:${HOME}/bin
grep -q "export PATH=.*\${HOME}/bin.*" ${HOME}/.asm-workshop.bash || echo "export PATH=\$PATH:\${HOME}/bin" >> ${HOME}/.asm-workshop.bash
echo -e "\n"

export PV_INSTALLED=`which pv`
if [ -z ${PV_INSTALLED} ]; then
    nopv_and_execute "sudo apt-get update && sudo apt-get -y install pv"
    nopv_and_execute "sudo mv /usr/bin/pv ${HOME}/bin/pv"
else
    title_no_wait "pv is already installed and in the ${PV_INSTALLED} folder."
fi
echo -e "\n"

[[ ! -e ${HOME}/.asm-workshop.bash ]] && touch ${HOME}/.asm-workshop.bash

title_no_wait "Creating custom shell prompt file..."
print_and_execute "cp ${SCRIPT_DIR}/../scripts/krompt.bash ${HOME}/.krompt.bash"
grep -q ".krompt.bash" ${HOME}/.asm-workshop.bash || (echo "source ${HOME}/.krompt.bash" >> ${HOME}/.asm-workshop.bash)

if [[ ${ASM_UPDATE_BASHRC:-"true"} == "true" ]]; then
    title_no_wait "Updating bash prompt..."
    grep -q ".asm-workshop.bash" ${HOME}/.bashrc || (echo "source ${HOME}/.asm-workshop.bash" >> ${HOME}/.bashrc)
else
    title_no_wait "Adding asm-init alias to bashrc..."
    grep -q "alias asm-init" ${HOME}/.bashrc || (echo "alias asm-init='source ${HOME}/.asm-workshop.bash'" >> ${HOME}/.bashrc)
    echo -e "\n"
fi

if [[ -z ${MY_USER} ]]; then
    error_no_wait "Missing env MY_USER"
    exit 1
fi

ORG_USER=${MY_USER%@*}
ORG_USER=${ORG_USER:0:7}

title_and_wait "Verify that you are logged in with the correct user. The user should be ${MY_USER}."
print_and_execute "gcloud config list account --format=json | jq -r .core.account"
export ACCOUNT=`gcloud config list account --format=json | jq -r .core.account`
if [ ${ACCOUNT} == ${MY_USER} ]; then
    title_no_wait "You are logged in with the correct user account."
else
    error_no_wait "You are logged in with user ${ACCOUNT}, which does not match the intended ${MY_USER} user. Ensure you are logged in with ${MY_USER} by running 'gcloud auth login' and following the instructions. Exiting script."
    exit 1
fi
echo -e "\n"

title_and_wait "Get the terraform-admin-project ID."
project=$(gcloud projects list --filter="name~^${ORG_USER}.*-tf" --format='value(projectId)')
print_and_execute "export TF_ADMIN=${project}"
print_and_execute "echo ${TF_ADMIN}"
if [[ -z ${TF_ADMIN} ]]; then
  error_no_wait "Uh oh! We cannot retrieve your terraform-admin project ID. You cannot continue the workshop without this. Please contact your lab administrator"
  error_no_wait "Here is a list of all projects accessible by you. Exiting script..."
  gcloud projects list
  exit 1
fi
echo -e "\n"

title_and_wait "Get the ops-project ID."
project=$(gcloud projects list --filter="name~^${ORG_USER}.*-ops" --format='value(projectId)')
print_and_execute "export TF_VAR_ops_project_name=${project}"
print_and_execute "echo ${TF_VAR_ops_project_name}"
if [[ -z ${TF_VAR_ops_project_name} ]]; then
  error_no_wait "Uh oh! We cannot retrieve your terraform-ops project ID. You cannot continue the workshop without this. Please contact your lab administrator"
  error_no_wait "Here is a list of all projects accessible by you. Exiting script..."
  gcloud projects list
  exit 1
fi
echo -e "\n"

title_and_wait "Get the variables for your environment. The variables include projects IDs, GKE cluster context, regions, zones etc."
print_and_execute "mkdir -p ${WORKDIR}/asm/vars"
export VARS_FILE=${WORKDIR}/asm/vars/vars.sh
print_and_execute "gsutil cp gs://${TF_ADMIN}/vars/vars.sh ${VARS_FILE}"
print_and_execute "echo \"export WORKDIR=${WORKDIR}\" >> ${VARS_FILE}"
print_and_execute "echo \"cd \${WORKDIR}\" >> ${HOME}/.asm-workshop.bash"
echo -e "\n"

title_no_wait "Verify the infrastructure Cloud Build finished successfully."
title_no_wait "Navigate to the terraform-admin-project Cloud Build page and inspect the latest build."
title_no_wait "Click on the following link to get to the terraform-admin-project Cloud Build page."
print_and_execute "source ${VARS_FILE}"
print_and_execute "echo \"https://console.cloud.google.com/cloud-build/builds?project=${TF_ADMIN}\""
title_and_wait "Click on the link above. Click on the Build ID. You should only see one build ID. Inspect the build steps."

title_no_wait "Verify the k8s-repo Cloud Build finished successfully."
title_no_wait "Navigate to the ops-project Cloud Build page and inspect the latest build."
title_no_wait "Click on the following link to get to the ops-project Cloud Build page."
print_and_execute "echo \"https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}\""
title_and_wait "Click on the link above. Click on the Build ID. You should only see one build ID. Inspect the build steps."

title_no_wait "Get credentials for all clusters and create KUBECONFIG file."
title_and_wait "The kubeconfig file is located at ${WORKDIR}/asm/gke/kubemesh."
print_and_execute "${SCRIPT_DIR}/../scripts/setup-gke-vars-kubeconfig.sh"
print_and_execute "source ${VARS_FILE}"
print_and_execute "export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh"
echo -e "\n"
title_and_wait "Adding ${VARS_FILE} and KUBECONFIG vars to bashrc for persistence across multiple Cloud Shell sessions."
print_and_execute "grep -q \"source ${VARS_FILE}\" ${HOME}/.asm-workshop.bash || (echo \"source ${VARS_FILE}\" >> ${HOME}/.asm-workshop.bash)"
print_and_execute "grep -q \"export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh\" ${HOME}/.asm-workshop.bash || (echo \"export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh\" >> ${HOME}/.asm-workshop.bash)"
echo -e "\n"

title_and_wait "Confirm you can see all six GKE cluster contexts."
print_and_execute "kubectl config view -ojson | jq -r '.clusters[].name'"
export NUM_OF_CLUSTERS=`kubectl config view -ojson | jq -r '.clusters[].name' | wc -l`
if [ ${NUM_OF_CLUSTERS} == 6 ]; then
    title_no_wait "You have ${NUM_OF_CLUSTERS} in your kubeconfig file. Looks good."
else
    error_no_wait "Uh oh! It looks like you have ${NUM_OF_CLUSTERS} in your kubeconfig file."
    error_no_wait "You cannot proceed with the workshop until you have all six clusters in your kubeconfig."
    error_no_wait "Exiting script."
    exit 1
fi
echo -e "\n"

title_and_wait "Verify the entire Istio control plane is deployed and all Pods are Running in both ops clusters."
title_no_wait "Getting Istio Pods in ops-1 cluster..."
print_and_execute "kubectl --context ${OPS_GKE_1} get pods -n istio-system"
echo -e "\n"
title_no_wait "Getting Istio Pods in ops-2 cluster..."
print_and_execute "kubectl --context ${OPS_GKE_2} get pods -n istio-system"
echo -e "\n"

title_no_wait "Confirming Istio controlplane is deployed and Ready on the ops clusters..."
echo -e "\n"
# define ops clusters contexts
declare -a OPS_CLUSTER_CONTEXTS
export OPS_CLUSTER_CONTEXTS=(
    ${OPS_GKE_1}
    ${OPS_GKE_2}
)

# Define OPS cluster deployments - the full Istio controlplane
declare -a OPS_ISTIO_DEPLOYMENTS
export OPS_ISTIO_DEPLOYMENTS=(grafana
                        istio-citadel
                        istio-ingressgateway
                        istio-egressgateway
                        istio-galley
                        istio-pilot
                        istio-policy
                        istio-telemetry
                        istio-tracing
                        istio-sidecar-injector
                        istiocoredns
                        kiali
                        prometheus
                        )

title_no_wait "Waiting until all Deployments are Ready..."
for cluster in ${OPS_CLUSTER_CONTEXTS[@]}
    do
        title_no_wait "for Cluster ${cluster}"
        for deployment in ${OPS_ISTIO_DEPLOYMENTS[@]}
            do
                is_deployment_ready ${cluster} istio-system ${deployment}
            done
        echo -e "\n"
    done
echo -e "\n"
title_no_wait "Istio Deployments are Ready in the ops clusters."

title_and_wait "Verify citadel, istio-sidecar-injector and coredns are deployed and all Pods are Running in all apps clusters."
title_no_wait "Getting Istio Pods in app-1 cluster in dev1 project..."
print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n istio-system"
echo -e "\n"
title_no_wait "Getting Istio Pods in app-2 cluster in dev1 project..."
print_and_execute "kubectl --context ${DEV1_GKE_2} get pods -n istio-system"
echo -e "\n"
title_no_wait "Getting Istio Pods in app-3 cluster in dev2 project..."
print_and_execute "kubectl --context ${DEV2_GKE_1} get pods -n istio-system"
echo -e "\n"
title_no_wait "Getting Istio Pods in app-4 cluster in dev2 project..."
print_and_execute "kubectl --context ${DEV2_GKE_2} get pods -n istio-system"
echo -e "\n"

title_no_wait "Confirming the required Istio controlplane components are deployed and Ready on the apps clusters..."
echo -e "\n"
# define apps clusters contexts
declare -a APP_CLUSTER_CONTEXTS
export APP_CLUSTER_CONTEXTS=(
    ${DEV1_GKE_1}
    ${DEV1_GKE_2}
    ${DEV2_GKE_1}
    ${DEV2_GKE_2}
)

# Define deployments running in shared clusters
# only citadel, sidecar-injector and optionally coredns should be running
declare -a APP_ISTIO_DEPLOYMENTS
export APP_ISTIO_DEPLOYMENTS=(
        istio-citadel
        istio-sidecar-injector
        istiocoredns
        )

title_no_wait "Waiting until all Deployments are Ready..."
for cluster in ${APP_CLUSTER_CONTEXTS[@]}
    do
        title_no_wait "for Cluster ${cluster}"
        for deployment in ${APP_ISTIO_DEPLOYMENTS[@]}
            do
                is_deployment_ready ${cluster} istio-system ${deployment}
            done
        echo -e "\n"
    done
echo -e "\n"
title_no_wait "Istio deployments are Ready in the apps clusters."

title_no_wait "Pilots running in the ops clusters use kubeconfig files to access and get services and endpoints from all apps clusters."
title_no_wait "The kubeconfig files for all four apps clusters are stored as secrets in the ops clusters."
title_and_wait "Ensure these secrets are created in both ops clusters."
echo -e "\n"
title_no_wait "Kubeconfig secrets in ops-1 cluster:"
print_and_execute "kubectl --context ${OPS_GKE_1} get secrets -l istio/multiCluster=true -n istio-system"
echo -e "\n"
title_no_wait "Kubeconfig secrets in ops-2 cluster:"
print_and_execute "kubectl --context ${OPS_GKE_2} get secrets -l istio/multiCluster=true -n istio-system"
echo -e "\n"
export OPS1_NUM_OF_SECRETS=`kubectl --context ${OPS_GKE_1} get secrets -l istio/multiCluster=true -n istio-system | wc -l`
export OPS2_NUM_OF_SECRETS=`kubectl --context ${OPS_GKE_2} get secrets -l istio/multiCluster=true -n istio-system | wc -l`
export OPS1_NUM_OF_SECRETS=$((${OPS2_NUM_OF_SECRETS}-1)) # num of lines include the header row. subtracting 1 to get num of secrets
export OPS2_NUM_OF_SECRETS=$((${OPS2_NUM_OF_SECRETS}-1)) # num of lines include the header row. subtracting 1 to get num of secrets
if [ ${OPS1_NUM_OF_SECRETS} == 4 ]; then
    title_no_wait "You show ${OPS1_NUM_OF_SECRETS} secrets in ops-1 cluster. One for each app cluster. Looks good."
else
    error_no_wait "You show ${OPS1_NUM_OF_SECRETS} secrets in ops-1 cluster. You should see 4 secrets, one for each app cluster. Exiting script."
    exit 1
fi
if [ ${OPS2_NUM_OF_SECRETS} == 4 ]; then
    title_no_wait "You show ${OPS2_NUM_OF_SECRETS} secrets in ops-2 cluster. One for each app cluster. Looks good."
else
    title_no_wait "You show ${OPS2_NUM_OF_SECRETS} secrets in ops-2 cluster. You should see 4 secrets, one for each app cluster. Exiting script."
    exit 1
fi
echo -e "\n"

title_no_wait "Congratulations! You have successfully completed the Infrastructure Setup - User Workflow lab."
echo -e "\n"