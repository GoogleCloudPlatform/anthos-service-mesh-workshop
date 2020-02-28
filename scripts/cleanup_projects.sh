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

# TASK: This script deletes all projects, folders, including the terraform admin project

# Font colors
export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color

SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

source ${VARS_FILE}
export ADMIN_USER=$(gcloud config get-value account)

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p logs
export LOG_FILE=${SCRIPT_DIR}/../logs/cleanup-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

echo -e "\n${CYAN}Switching users...${NC}" 
# Check ADMIN_USER variable exists
while [ -z ${ADMIN_USER} ]
    do
    read -p "$(echo -e ${CYAN}"Please provide your user email (your account must be Org Admin): "${NC})" ADMIN_USER
    done
gcloud config set account ${ADMIN_USER}

echo -e "\n${CYAN}Deleting cloud endpoint service...${NC}" 
gcloud endpoints services delete frontend.endpoints.${TF_VAR_ops_project_name}.cloud.goog --project $TF_VAR_ops_project_name --async --quiet

echo -e "\n${CYAN}Deleting dev1, dev2, dev3 and ops projects...${NC}"
if gcloud projects list --filter $TF_VAR_dev1_project_name | grep $TF_VAR_dev1_project_name; then
  gcloud projects delete $TF_VAR_dev1_project_name --quiet
fi
if gcloud projects list --filter $TF_VAR_dev2_project_name | grep $TF_VAR_dev2_project_name; then
  gcloud projects delete $TF_VAR_dev2_project_name --quiet
fi
if gcloud projects list --filter $TF_VAR_dev3_project_name | grep $TF_VAR_dev3_project_name; then
  gcloud projects delete $TF_VAR_dev3_project_name --quiet
fi
if gcloud projects list --filter $TF_VAR_ops_project_name | grep $TF_VAR_ops_project_name; then
  gcloud projects delete $TF_VAR_ops_project_name --quiet
fi

echo -e "\n${CYAN}Removing shared vpc lien on the host project...${NC}" 
export LIEN_ID=$(gcloud alpha resource-manager liens list --project=${TF_VAR_host_project_name} | awk 'NR==2 {print $1}')
if [[ -n $LIEN_ID ]]; then
  gcloud alpha resource-manager liens delete $LIEN_ID;
fi

echo -e "\n${CYAN}Deleting host project...${NC}"
if gcloud projects list --filter $TF_VAR_host_project_name | grep $TF_VAR_host_project_name; then
  gcloud projects delete $TF_VAR_host_project_name --quiet
fi

echo -e "\n${CYAN}Deleting terraform admin project...${NC}" 
if gcloud projects list --filter $TF_ADMIN | grep $TF_ADMIN; then
  gcloud projects delete $TF_ADMIN --quiet
fi

echo -e "\n${CYAN}Deleting folder...${NC}"
gcloud resource-manager folders delete ${TF_VAR_folder_id}

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

echo -e "\n${CYAN}Removing CloudBuild SA billing user permissions from billing account ...${NC}"
gcloud beta billing accounts get-iam-policy ${TF_VAR_billing_account} --format=json | \
    jq '(.bindings[] | select(.role=="roles/billing.user").members) -= ["serviceAccount:'${TF_CLOUDBUILD_SA}'"]' > ${SCRIPT_DIR}/../tmp/cloudbuild_billing-iam-policy.json
gcloud beta billing accounts set-iam-policy ${TF_VAR_billing_account} ${SCRIPT_DIR}/../tmp/cloudbuild_billing-iam-policy.json

echo -e "\n${CYAN}Remove infra git repo...${NC}" 
(cd ${SCRIPT_DIR}/../infrastructure && rm -Rf .git)

echo -e "\n${CYAN}Remove gke, istio-${ISTIO_VERSION}, vars and tmp folder...${NC}" 
#rm -rf ${SCRIPT_DIR}/../gke
#rm -rf ${SCRIPT_DIR}/../istio-${ISTIO_VERSION}
#rm -rf ${SCRIPT_DIR}/../vars
#rm -rf ${SCRIPT_DIR}/../tmp

echo -e "\n${CYAN}Unsetting RANDOM_PERSIST variable...${NC}" 
unset RANDOM_PERSIST
