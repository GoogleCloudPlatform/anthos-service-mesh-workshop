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
echo "${bold}*** Lab: Infrastructure Setup - User Workflow ***${normal}"
echo -e "\n"

# START INSTRUCTIONS HERE - EXAMPLE BELOW

echo "${bold}Download kustomize cli and pv tools. Press ENTER to continue...${normal}"
read -p ''
nopv_and_execute "mkdir -p ${HOME}/bin && cd ${HOME}/bin"
export KUSTOMIZE_FILEPATH="${HOME}/bin/kustomize"
if [ -f ${KUSTOMIZE_FILEPATH} ]; then
    echo -e "kustomize is already installed and in the ${KUSTOMIZE_FILE} folder."
else 
    nopv_and_execute "curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash"
    nopv_and_execute "export PATH=$PATH:${HOME}/bin"
    nopv_and_execute "echo \"export PATH=$PATH:${HOME}/bin\" >> ~/.bashrc"
fi
echo -e "\n"

export PV_INSTALLED=`which pv`
if [ -z ${PV_INSTALLED} ]; then
    nopv_and_execute "sudo apt-get update && sudo apt-get -y install pv"
    nopv_and_execute "sudo mv /usr/bin/pv ${HOME}/bin/pv"
else
    echo -e "pv is already installed and in the ${PV_INSTALLED} folder."
fi
echo -e "\n"


echo "${bold}Verify that you are logged in with the correct user. The user should be ${MY_USER}. Press ENTER to continue...${normal}"
read -p ''
print_and_execute "gcloud config list account --format=json | jq -r .core.account"
export ACCOUNT=`gcloud config list account --format=json | jq -r .core.account`
if [ ${ACCOUNT} == ${MY_USER} ]; then
    echo -e "You are logged in with the correct user account."
else
    echo -e "You are logged in with user ${ACCOUNT}, which does not match the intended ${MY_USER}. Ensure you are logged in with ${MY_USER} by running 'gcloud auth login' and following the instructions. Exiting script."
    exit 1
fi
echo -e "\n"

echo "${bold}Get the terraform-admin-project ID. Press ENTER to continue...${normal}"
read -p ''
print_and_execute "export TF_ADMIN=$(gcloud projects list | grep tf- | awk '{ print $1 }')"
print_and_execute "echo ${TF_ADMIN}"
if [ ${TF_ADMIN} == 'null' ]; then
  echo -e "Uh oh! We cannot retrieve your terraform-admin project ID. You cannot continue the workshop without this. Please contact your lab administrator"
  echo -e "Here is a list of all projects accessible by you. Exiting script..." 
  gcloud projects list 
  exit 1
fi
echo -e "\n"

echo "${bold}Get the variables for your environment. The variables include projects IDs, GKE cluster context, regions, zones etc. Press ENTER to continue...${normal}"
read -p ''
print_and_execute "mkdir -p ${WORKDIR}/asm/vars"
export VARS_FILE=${WORKDIR}/asm/vars/vars.sh
if [ -f ${VARS_FILE} ]; then
    echo -e "${VARS_FILE} already exists. Skipping step."
else
    print_and_execute "gsutil cp gs://${TF_ADMIN}/vars/vars.sh ${VARS_FILE}"
    print_and_execute "echo \"export WORKDIR=${WORKDIR}\" >> ${VARS_FILE}"
fi
echo -e "\n"

echo "${bold}Verify the infrastructure Cloud Build finished successfully.${normal}"
echo "${bold}Navigate to the terraform-admin-project Cloud Build page and inspect the latest build.${normal}"
echo "${bold}Click on the following link to get to the terraform-admin-project Cloud Build page.${normal}"
print_and_execute "source ${VARS_FILE}"
print_and_execute "echo \"https://console.cloud.google.com/cloud-build/builds?project=${TF_ADMIN}\""
echo -e "\n"
echo "${bold}Click on the link above. Click on the Build ID. You should only see one build ID. Inspect the build steps. Press ENTER to continue...${normal}"
read -p ''

echo "${bold}Verify the k8s-repo Cloud Build finished successfully.${normal}"
echo "${bold}Navigate to the ops-project Cloud Build page and inspect the latest build.${normal}"
echo "${bold}Click on the following link to get to the ops-project Cloud Build page.${normal}"
print_and_execute "echo \"https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}\""
echo -e "\n"
echo "${bold}Click on the link above. Click on the Build ID. You should only see one build ID. Inspect the build steps. Press ENTER to continue...${normal}"
read -p ''

echo "${bold}Get credentials for all clusters and create KUBECONFIG file.${normal}"
echo "${bold}The kubeconfig file is located at ${WORKDIR}/asm/gke/kubemesh ${normal}"
echo "${bold}Please ENTER to continue...${normal}"
read -p ''
print_and_execute "${SCRIPT_DIR}/../scripts/setup-gke-vars-kubeconfig.sh"
print_and_execute "source ${VARS_FILE}"
print_and_execute "export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh"
echo "${bold}Adding ${VARS_FILE} and KUBECONFIG vars to bashrc for persistence across multiple Cloud Shell sessions. ${normal}"
print_and_execute "echo \"source ${VARS_FILE}\" >> ~/.bashrc"
print_and_execute "echo \"export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh\" >> ~/.bashrc"
echo -e "\n"

echo "${bold}Confirm you can see all six GKE cluster contexts. Please ENTER to continue...${normal}"
read -p ''
print_and_execute "kubectl config view -ojson | jq -r '.clusters[].name'"
export NUM_OF_CLUSTERS=`kubectl config view -ojson | jq -r '.clusters[].name' | wc -l`
if [ ${NUM_OF_CLUSTERS} == 6 ]; then
    echo -e "You have ${NUM_OF_CLUSTERS} in your kubeconfig file. Looks good."
else
    echo -e "Uh oh! It looks like you have ${NUM_OF_CLUSTERS} in your kubeconfig file."
    echo -e "You cannot proceed with the workshop until you have all six clusters in your kubeconfig."
    echo -r "Exiting script."
    exit 1
fi
echo -e "\n"

echo "${bold}Verify the entire Istio control plane is deployed and all Pods are Running in both ops clusters. Please ENTER to continue...${normal}"
read -p ''
print_and_execute "kubectl --context ${OPS_GKE_1} get pods -n istio-system"
print_and_execute "kubectl --context ${OPS_GKE_2} get pods -n istio-system"
echo -e "\n"

echo "${bold}Verify citadel, istio-sidecar-injector and coredns are deployed and all Pods are Running in all apps clusters. Please ENTER to continue...${normal}"
read -p ''
print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n istio-system"
print_and_execute "kubectl --context ${DEV1_GKE_2} get pods -n istio-system"
print_and_execute "kubectl --context ${DEV2_GKE_1} get pods -n istio-system"
print_and_execute "kubectl --context ${DEV2_GKE_2} get pods -n istio-system"
echo -e "\n"

echo "${bold}Pilots running in the ops clusters use kubeconfig files to access and get services and endpoints from all apps clusters.${normal}"
echo "${bold}The kubeconfig files for all four apps clusters are stored as secrets in the ops clusters.${normal}"
echo "${bold}Ensure these secrets are created in both ops clusters.${normal}"
echo "${bold}Please ENTER to continue...${normal}"
read -p ''
print_and_execute "kubectl --context ${OPS_GKE_1} get secrets -l istio/multiCluster=true -n istio-system"
print_and_execute "kubectl --context ${OPS_GKE_2} get secrets -l istio/multiCluster=true -n istio-system"
echo -e "\n"
export OPS1_NUM_OF_SECRETS=`kubectl --context ${OPS_GKE_1} get secrets -l istio/multiCluster=true -n istio-system | wc -l`
export OPS2_NUM_OF_SECRETS=`kubectl --context ${OPS_GKE_2} get secrets -l istio/multiCluster=true -n istio-system | wc -l`
export OPS1_NUM_OF_SECRETS=${OPS2_NUM_OF_SECRETS} - 1
export OPS2_NUM_OF_SECRETS=${OPS2_NUM_OF_SECRETS} - 1
if [ ${OPS1_NUM_OF_SECRETS} == 4 ]; then
    echo "${bold}You show ${OPS1_NUM_OF_SECRETS} secrets in ops-1 cluster. One for each app cluster. Looks good.${normal}"
else
    echo "${bold}You show ${OPS1_NUM_OF_SECRETS} secrets in ops-1 cluster. You should see 4 secrets, one for each app cluster. Exiting script.${normal}"
    exit 1
fi
if [ ${OPS2_NUM_OF_SECRETS} == 4 ]; then
    echo "${bold}You show ${OPS2_NUM_OF_SECRETS} secrets in ops-2 cluster. One for each app cluster. Looks good.${normal}"
else
    echo "${bold}You show ${OPS2_NUM_OF_SECRETS} secrets in ops-2 cluster. You should see 4 secrets, one for each app cluster. Exiting script.${normal}"
    exit 1
fi
echo -e "\n"

echo "${bold}Congratulations! You have successfully completed the Infrastructure Setup - User Workflow lab.${normal}"
echo -e "\n"