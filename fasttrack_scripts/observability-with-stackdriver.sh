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
export LAB_NAME=observability-with-stackdriver

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Observability with Stackdriver

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
echo "${bold}*** Lab: Observability with Stackdriver ***${normal}"
echo -e "\n"

# https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop/#6
title_and_wait "Install the istio to stackdriver config file."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute " "
print_and_execute "cd gke-asm-1-r1-prod/istio-telemetry"
print_and_execute "kustomize edit add resource istio-telemetry.yaml"
print_and_execute " "
print_and_execute "cd ../../gke-asm-2-r2-prod/istio-telemetry"
print_and_execute "kustomize edit add resource istio-telemetry.yaml"

echo "${bold}Commit to k8s-repo. Press ENTER to continue...${normal}"
read -p ''
print_and_execute "cd ../../"
print_and_execute "git add . && git commit -am \"Install istio to stackdriver configuration\""
print_and_execute "git push"
 
echo "${bold}Wait for rollout to complete. Press ENTER to continue...${normal}"
read -p ''
print_and_execute "../asm/scripts/stream_logs.sh $TF_VAR_ops_project_name"
 
echo "${bold}Verify the Istio → Stackdriver integration Get the Stackdriver Handler CRD. Press ENTER to continue...${normal}"
read -p ''

print_and_execute "kubectl --context ${OPS_GKE_1} get handler -n istio-system"
 
echo "${bold}Verify that the Istio metrics export to Stackdriver is working. Click the link output from this command: Press ENTER to continue...${normal}"
read -p ''

echo "https://console.cloud.google.com/monitoring/metrics-explorer?cloudshell=false&project=${TF_VAR_ops_project_name}"

