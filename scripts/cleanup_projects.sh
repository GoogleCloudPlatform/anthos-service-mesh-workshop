#!/usr/bin/env bash

# TASK: This script deletes all projects, folders, including the terraform admin project

# Font colors
export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color

SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

source ${SCRIPT_DIR}/../vars/vars.sh

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p logs
export LOG_FILE=${SCRIPT_DIR}/../logs/cleanup-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

echo -e "\n${CYAN}Switching users...${NC}" 
# Check MY_USER variable exists
while [ -z ${MY_USER} ]
    do
    read -p "$(echo -e ${CYAN}"Please provide your user email (your account must be Org Admin): "${NC})" MY_USER
    done
gcloud config set account ${MY_USER}

echo -e "\n${CYAN}Deleting dev1, dev2 and ops projects...${NC}" 
gcloud projects delete ${TF_VAR_dev1_project_name} --quiet
gcloud projects delete ${TF_VAR_dev2_project_name} --quiet
gcloud projects delete ${TF_VAR_ops_project_name} --quiet

echo -e "\n${CYAN}Removing shared vpc lien on the host project...${NC}" 
export LIEN_ID=$(gcloud alpha resource-manager liens list --project=${TF_VAR_host_project_name} | awk 'NR==2 {print $1}')
gcloud alpha resource-manager liens delete ${LIEN_ID}

echo -e "\n${CYAN}Deleting host project...${NC}" 
gcloud projects delete ${TF_VAR_host_project_name} --quiet

echo -e "\n${CYAN}Deleting terraform admin project...${NC}" 
gcloud projects delete ${TF_ADMIN} --quiet

echo -e "\n${CYAN}Getting folder ID...${NC}" 
export FOLDER_ID=$(gcloud resource-manager folders list --organization=${TF_VAR_org_id} | grep ${TF_VAR_folder_display_name} | awk '{print $3}')

echo -e "\n${CYAN}Deleting folder...${NC}" 
gcloud resource-manager folders delete ${FOLDER_ID}

echo -e "\n${CYAN}Removing cloudbuild service account project creator IAM role at the Org level...${NC}" 
gcloud organizations remove-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/resourcemanager.projectCreator 


echo -e "\n${CYAN}Removing cloudbuild service account billing user IAM role at the Org level...${NC}" 
gcloud organizations remove-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/billing.user 


echo -e "\n${CYAN}Removing cloudbuild service account compute admin IAM role at the Org level...${NC}" 
gcloud organizations remove-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/compute.admin 


echo -e "\n${CYAN}Removing cloudbuild service account folder creator IAM role at the Org level...${NC}" 
gcloud organizations remove-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/resourcemanager.folderCreator

echo -e "\n${CYAN}Remove infra git repo...${NC}" 
(cd ${SCRIPT_DIR}/../infrastructure && rm -Rf .git)

echo -e "\n${CYAN}Remove gke, istio-${ISTIO_VERSION}, vars and tmp folder...${NC}" 
rm -rf ${SCRIPT_DIR}/../gke
rm -rf ${SCRIPT_DIR}/../istio-${ISTIO_VERSION}
rm -rf ${SCRIPT_DIR}/../vars
rm -rf ${SCRIPT_DIR}/../tmp

echo -e "\n${CYAN}Unsetting RANDOM_PERSIST variable...${NC}" 
unset RANDOM_PERSIST
