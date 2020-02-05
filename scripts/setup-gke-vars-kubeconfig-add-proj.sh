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
# TASK: Adding new clusters to vars and creating kubeconfig entries

# Setting up GKE cluster names, regions, zones and contexts and add them to vars.sh

# Font colors

SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color

# Create a log file and send stdout and stderr to console and log file
export LOG_FILE=setup-gke-vars-$(date +%s).log
touch ${SCRIPT_DIR}/../logs/${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${SCRIPT_DIR}/../logs/${LOG_FILE})

# Add GKE vars to vars.sh and re-source vars


echo -e "\n${CYAN}Adding new GKE cluster names, regions, zones and contexts to vars.sh...${NC}"

export VARS_FILE=${SCRIPT_DIR}/../vars/vars.sh
source ${VARS_FILE}

# Create GKE vars
echo -e "export OPS_GKE_3_CLUSTER=gke-asm-3-r3-prod" | tee -a ${VARS_FILE}
echo -e "export DEV3_GKE_1_CLUSTER=gke-5-apps-r3b-prod" | tee -a ${VARS_FILE}
echo -e "export DEV3_GKE_2_CLUSTER=gke-6-apps-r3c-prod" | tee -a ${VARS_FILE}
echo -e "export OPS_GKE_3_LOCATION=us-east1" | tee -a ${VARS_FILE}
echo -e "export DEV3_GKE_1_LOCATION=us-east1-b" | tee -a ${VARS_FILE}
echo -e "export DEV3_GKE_2_LOCATION=us-east1-c" | tee -a ${VARS_FILE}

# Create cluster contexts
source ${VARS_FILE}
echo -e "export OPS_GKE_3=gke_${TF_VAR_ops_project_name}_${OPS_GKE_3_LOCATION}_${OPS_GKE_3_CLUSTER}" | tee -a ${VARS_FILE}
echo -e "export DEV3_GKE_1=gke_${TF_VAR_dev3_project_name}_${DEV3_GKE_1_LOCATION}_${DEV3_GKE_1_CLUSTER}" | tee -a ${VARS_FILE}
echo -e "export DEV3_GKE_2=gke_${TF_VAR_dev3_project_name}_${DEV3_GKE_2_LOCATION}_${DEV3_GKE_2_CLUSTER}" | tee -a ${VARS_FILE}

# Create kubeconfig file
source ${VARS_FILE}
export KUBECONFIG=./gke/kubemesh
gcloud container clusters get-credentials "${OPS_GKE_3_CLUSTER}" --region "${OPS_GKE_3_LOCATION}" --project "${TF_VAR_ops_project_name}"
gcloud container clusters get-credentials "${DEV3_GKE_1_CLUSTER}" --zone "${DEV3_GKE_1_LOCATION}" --project "${TF_VAR_dev3_project_name}"
gcloud container clusters get-credentials "${DEV3_GKE_2_CLUSTER}" --zone "${DEV3_GKE_2_LOCATION}" --project "${TF_VAR_dev3_project_name}"
