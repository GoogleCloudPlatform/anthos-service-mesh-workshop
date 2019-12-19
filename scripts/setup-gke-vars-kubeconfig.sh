#!/usr/bin/env bash

# TASK 2: Setting up Istio

# Setting up GKE cluster names, regions, zones and contexts and add them to vars.sh 

# Font colors
export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color

# Create a log file and send stdout and stderr to console and log file 
export LOG_FILE=setup-gke-vars-$(date +%s).log
touch ./logs/${LOG_FILE}
exec 2>&1
exec &> >(tee -i ./logs/${LOG_FILE})

# Add GKE vars to vars.sh and re-source vars

echo -e "\n${CYAN}Adding GKE cluster names, regions, zones and contexts to vars.sh...${NC}" 

export VARS_FILE=./vars/vars.sh
source ${VARS_FILE}

# Create GKE vars
echo -e "export ISTIO_VERSION=1.4.0" | tee -a ${VARS_FILE}
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
export KUBECONFIG=./gke/kubemesh
gcloud beta container clusters get-credentials "${OPS_GKE_1_CLUSTER}" --region "${OPS_GKE_1_LOCATION}" --project "${TF_VAR_ops_project_name}"
gcloud beta container clusters get-credentials "${OPS_GKE_2_CLUSTER}" --region "${OPS_GKE_2_LOCATION}" --project "${TF_VAR_ops_project_name}"
gcloud container clusters get-credentials "${DEV1_GKE_1_CLUSTER}" --zone "${DEV1_GKE_1_LOCATION}" --project "${TF_VAR_dev1_project_name}"
gcloud container clusters get-credentials "${DEV1_GKE_2_CLUSTER}" --zone "${DEV1_GKE_2_LOCATION}" --project "${TF_VAR_dev1_project_name}"
gcloud container clusters get-credentials "${DEV2_GKE_1_CLUSTER}" --zone "${DEV2_GKE_1_LOCATION}" --project "${TF_VAR_dev2_project_name}"
gcloud container clusters get-credentials "${DEV2_GKE_2_CLUSTER}" --zone "${DEV2_GKE_2_LOCATION}" --project "${TF_VAR_dev2_project_name}"
