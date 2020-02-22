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

# TASK 2: Setting up Istio

# Setting up GKE cluster names, regions, zones and contexts and add them to vars.sh 

# Font colors
export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color

# Export a SCRIPT_DIR var and make all links relative to SCRIPT_DIR
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

# Create a log file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/setup-gke-vars-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})


# Add GKE vars to vars.sh and re-source vars
echo -e "\n${CYAN}Adding GKE cluster names, regions, zones and contexts to vars.sh...${NC}" 

export VARS_FILE=${SCRIPT_DIR}/../vars/vars.sh
source ${VARS_FILE}

# Create GKE vars
echo -e "export ISTIO_VERSION=1.4.3" | tee -a ${VARS_FILE}
echo -e "export OPS_GKE_1_CLUSTER=gke-asm-1-r1-prod" | tee -a ${VARS_FILE}
echo -e "export OPS_GKE_2_CLUSTER=gke-asm-2-r2-prod" | tee -a ${VARS_FILE}
echo -e "export DEV1_GKE_1_CLUSTER=gke-1-apps-r1a-prod" | tee -a ${VARS_FILE}
echo -e "export DEV1_GKE_2_CLUSTER=gke-2-apps-r1b-prod" | tee -a ${VARS_FILE}
echo -e "export DEV2_GKE_1_CLUSTER=gke-3-apps-r2a-prod" | tee -a ${VARS_FILE}
echo -e "export DEV2_GKE_2_CLUSTER=gke-4-apps-r2b-prod" | tee -a ${VARS_FILE}
echo -e "export OPS_GKE_1_LOCATION=us-west1" | tee -a ${VARS_FILE}
echo -e "export OPS_GKE_2_LOCATION=us-central1" | tee -a ${VARS_FILE}
echo -e "export DEV1_GKE_1_LOCATION=us-west1-a" | tee -a ${VARS_FILE}
echo -e "export DEV1_GKE_2_LOCATION=us-west1-b" | tee -a ${VARS_FILE}
echo -e "export DEV2_GKE_1_LOCATION=us-central1-a" | tee -a ${VARS_FILE}
echo -e "export DEV2_GKE_2_LOCATION=us-central1-b" | tee -a ${VARS_FILE}

# Create cluster contexts
source ${VARS_FILE}
echo -e "export OPS_GKE_1=gke_${TF_VAR_ops_project_name}_${OPS_GKE_1_LOCATION}_${OPS_GKE_1_CLUSTER}" | tee -a ${VARS_FILE}
echo -e "export OPS_GKE_2=gke_${TF_VAR_ops_project_name}_${OPS_GKE_2_LOCATION}_${OPS_GKE_2_CLUSTER}" | tee -a ${VARS_FILE}
echo -e "export DEV1_GKE_1=gke_${TF_VAR_dev1_project_name}_${DEV1_GKE_1_LOCATION}_${DEV1_GKE_1_CLUSTER}" | tee -a ${VARS_FILE}
echo -e "export DEV1_GKE_2=gke_${TF_VAR_dev1_project_name}_${DEV1_GKE_2_LOCATION}_${DEV1_GKE_2_CLUSTER}" | tee -a ${VARS_FILE}
echo -e "export DEV2_GKE_1=gke_${TF_VAR_dev2_project_name}_${DEV2_GKE_1_LOCATION}_${DEV2_GKE_1_CLUSTER}" | tee -a ${VARS_FILE}
echo -e "export DEV2_GKE_2=gke_${TF_VAR_dev2_project_name}_${DEV2_GKE_2_LOCATION}_${DEV2_GKE_2_CLUSTER}" | tee -a ${VARS_FILE}

# Create kubeconfig file
source ${VARS_FILE}
export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh
gcloud container clusters get-credentials "${OPS_GKE_1_CLUSTER}" --region "${OPS_GKE_1_LOCATION}" --project "${TF_VAR_ops_project_name}"
gcloud container clusters get-credentials "${OPS_GKE_2_CLUSTER}" --region "${OPS_GKE_2_LOCATION}" --project "${TF_VAR_ops_project_name}"
gcloud container clusters get-credentials "${DEV1_GKE_1_CLUSTER}" --zone "${DEV1_GKE_1_LOCATION}" --project "${TF_VAR_dev1_project_name}"
gcloud container clusters get-credentials "${DEV1_GKE_2_CLUSTER}" --zone "${DEV1_GKE_2_LOCATION}" --project "${TF_VAR_dev1_project_name}"
gcloud container clusters get-credentials "${DEV2_GKE_1_CLUSTER}" --zone "${DEV2_GKE_1_LOCATION}" --project "${TF_VAR_dev2_project_name}"
gcloud container clusters get-credentials "${DEV2_GKE_2_CLUSTER}" --zone "${DEV2_GKE_2_LOCATION}" --project "${TF_VAR_dev2_project_name}"
