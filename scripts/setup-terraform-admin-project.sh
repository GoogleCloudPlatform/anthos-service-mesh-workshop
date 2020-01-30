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

# SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

# TASK: Create a terraform admin project to provision GCP infrastructure

# Font colors
export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color


# Create a vars folder and file
mkdir -p ${SCRIPT_DIR}/../vars
export VARS_FILE=${SCRIPT_DIR}/../vars/vars.sh
touch ${VARS_FILE}
chmod +x ${VARS_FILE}
source ${VARS_FILE}

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p logs
export LOG_FILE=${SCRIPT_DIR}/../logs/setup-terraform-project-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})


# Create a gke folder and a kubeconfig file
# Used to keep a separate kubeconfig file
mkdir -p gke
touch ${SCRIPT_DIR}/../gke/kubemesh

# Ensure Org ID is defined otherwise collect
while [ -z ${TF_VAR_org_id} ]
    do
    read -p "$(echo -e ${CYAN}"Please provide your Organization ID (your active account must be Org Admin): "${NC})" TF_VAR_org_id
    done


# Ensure Billing account is defined otherwise collect
while [ -z ${TF_VAR_billing_account} ]
    do
    read -p "$(echo -e ${CYAN}"Please provide your Billing Account ID (your active account must be Billing Account Admin): "${NC})" TF_VAR_billing_account
    done


# Print out commands except echo, read, case, while and if
# trap '! [[ "$BASH_COMMAND" =~ ^(echo|read|if|case|while|tee) ]] && \
# cmd=`eval echo "$BASH_COMMAND" 2>/dev/null` && echo + "$cmd"' DEBUG


echo -e "${CYAN}Your Organization ID is ${TF_VAR_org_id}${NC}" 
echo -e "${CYAN}Your Billing Account is ${TF_VAR_billing_account}${NC}" 

RANDOM_PERSIST=${RANDOM_PERSIST:-${RANDOM}}

echo -e "\n${CYAN}Defining terraform admin project ID, SA and SA credentials location...${NC}"
ORG_USER=${MY_USER?env not set}
ORG_USER=${MY_USER%@*}
ORG_USER=${ORG_USER:0:7}
export TF_VAR_folder_display_name=${ORG_USER}-${RANDOM_PERSIST}-asm
PROJECT_ID_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
export TF_ADMIN_NAME=${ORG_USER}-${RANDOM_PERSIST}-tf
export TF_ADMIN=${TF_ADMIN_NAME}-${PROJECT_ID_SUFFIX}


echo -e "\n${CYAN}Checking for existing asm workshop folder...${NC}"
export TF_VAR_folder_id=$(gcloud resource-manager folders list --organization=${TF_VAR_org_id} | grep ${TF_VAR_folder_display_name} | awk '{print $3}')
if [ "${TF_VAR_folder_id}" ]; then
   echo -e "\n${CYAN}Folder ${TF_VAR_folder_display_name} already exists.${NC}"
   else
       echo -e "\n${CYAN}Creating asm workshop folder ${TF_VAR_folder_display_name}...${NC}"
       gcloud resource-manager folders create --display-name=${TF_VAR_folder_display_name} --organization=${TF_VAR_org_id}
       export TF_VAR_folder_id=$(gcloud resource-manager folders list --organization=${TF_VAR_org_id} | grep ${TF_VAR_folder_display_name} | awk '{print $3}')
fi

# TODO: If project already exists then have script retry with a diff PROJECT_ID_SUFFIX value
echo -e "\n${CYAN}Creating terraform admin project...${NC}"
gcloud projects create ${TF_ADMIN} \
--folder ${TF_VAR_folder_id} \
--name ${TF_ADMIN_NAME} \
--set-as-default


echo -e "\n${CYAN}Linking billing account to the terraform admin project...${NC}"
gcloud beta billing projects link ${TF_ADMIN} \
--billing-account ${TF_VAR_billing_account}

echo -e "\n${CYAN}Enabling APIs that are required in the projects that terraform creates...${NC}"
gcloud services enable cloudresourcemanager.googleapis.com \
cloudbilling.googleapis.com \
iam.googleapis.com \
compute.googleapis.com \
container.googleapis.com \
serviceusage.googleapis.com \
sourcerepo.googleapis.com \
cloudbuild.googleapis.com \
contextgraph.googleapis.com \
servicemanagement.googleapis.com

echo -e "\n${CYAN}Getting Terraform admin project cloudbuild service account...${NC}"
export TF_CLOUDBUILD_SA=$(gcloud projects describe $TF_ADMIN --format='value(projectNumber)')@cloudbuild.gserviceaccount.com

echo -e "\n${CYAN}Giving cloudbuild service account viewer role...${NC}"
gcloud projects add-iam-policy-binding ${TF_ADMIN} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/viewer

echo -e "\n${CYAN}Giving cloudbuild service account storage admin role...${NC}"
gcloud projects add-iam-policy-binding ${TF_ADMIN} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/storage.admin

echo -e "\n${CYAN}Giving cloudbuild service account project creator IAM role at the Org level...${NC}"
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/resourcemanager.projectCreator


echo -e "\n${CYAN}Giving cloudbuild service account billing user IAM role at the Org level...${NC}"
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/billing.user


echo -e "\n${CYAN}Giving cloudbuild service account compute admin IAM role at the Org level...${NC}"
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/compute.admin


echo -e "\n${CYAN}Giving cloudbuild service account folder creator IAM role at the Org level...${NC}"
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
--member serviceAccount:${TF_CLOUDBUILD_SA} \
--role roles/resourcemanager.folderCreator

echo -e "\n${CYAN}Giving ${MY_USER} Owner IAM permission at the folder level for folder ${TF_VAR_folder_display_name}...${NC}"
gcloud alpha resource-manager folders \
  add-iam-policy-binding ${TF_VAR_folder_id} \
  --member=user:${MY_USER} \
  --role=roles/owner

echo -e "\n${CYAN}Giving cloudbuild service account billing user role for the billing account...${NC}"
mkdir -p ${SCRIPT_DIR}/../tmp
gcloud beta billing accounts get-iam-policy ${TF_VAR_billing_account} --format=json | \
    jq '(.bindings[] | select(.role=="roles/billing.user").members) += ["serviceAccount:'${TF_CLOUDBUILD_SA}'"]' > ${SCRIPT_DIR}/../tmp/cloudbuild_billing-iam-policy.json
gcloud beta billing accounts set-iam-policy ${TF_VAR_billing_account} ${SCRIPT_DIR}/../tmp/cloudbuild_billing-iam-policy.json


echo -e "\n${CYAN}Creating gcs bucket for terraform state...${NC}"
gsutil mb -p ${TF_ADMIN} gs://${TF_ADMIN}

echo -e "\n${CYAN}Enabling versioning on the terraform state gcs bucket...${NC}"
gsutil versioning set on gs://${TF_ADMIN}

echo -e "\n${CYAN}Creating infrastructure cloud source repo...${NC}"
gcloud source repos create infrastructure

echo -e "\n${CYAN}Creating cloudbuild trigger for infrastructure deployment...${NC}"
gcloud alpha builds triggers create cloud-source-repositories \
--repo="infrastructure" --description="push to master" --branch-pattern="master" \
--build-config="cloudbuild.yaml"

echo -e "\n${CYAN}Setting default project and credentials...${NC}"
export GOOGLE_PROJECT=${TF_ADMIN}

echo -e "\n${CYAN}Creating vars file...${NC}"
echo -e "export MY_USER=${MY_USER}" | tee -a ${VARS_FILE}
echo -e "export ADMIN_USER=${ADMIN_USER}" | tee -a ${VARS_FILE}
echo -e "export RANDOM_PERSIST=${RANDOM_PERSIST}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_org_id=${TF_VAR_org_id}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_billing_account=${TF_VAR_billing_account}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_folder_id=${TF_VAR_folder_id}" | tee -a ${VARS_FILE}
echo -e "export TF_ADMIN=${TF_ADMIN}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_tfadmin=${TF_ADMIN}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_project_editor=${ADMIN_USER}" | tee -a ${VARS_FILE}
echo -e "export GOOGLE_PROJECT=${TF_ADMIN}" | tee -a ${VARS_FILE}
echo -e "export TF_CLOUDBUILD_SA=$(gcloud projects describe ${TF_ADMIN} --format='value(projectNumber)')@cloudbuild.gserviceaccount.com" | tee -a ${VARS_FILE}


echo -e "\n${CYAN}Setting new project names...${NC}"
echo -e "export TF_VAR_host_project_name=${ORG_USER}-${RANDOM_PERSIST}-host-${PROJECT_ID_SUFFIX}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_ops_project_name=${ORG_USER}-${RANDOM_PERSIST}-ops-${PROJECT_ID_SUFFIX}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_dev1_project_name=${ORG_USER}-${RANDOM_PERSIST}-dev1-${PROJECT_ID_SUFFIX}" | tee -a ${VARS_FILE}
echo -e "export TF_VAR_dev2_project_name=${ORG_USER}-${RANDOM_PERSIST}-dev2-${PROJECT_ID_SUFFIX}" | tee -a ${VARS_FILE}


source ${VARS_FILE}

# Add vars.sh to gcs bucket
gsutil cp ${VARS_FILE} gs://${TF_ADMIN}/vars/vars.sh

echo -e "\n${CYAN}Preparing terraform backends, shared states and vars...${NC}"
# Define an array of GCP resources
declare -a folders
folders=(
    'gcp/prod/gcp'
    'network/prod/host_project'
    'network/prod/shared_vpc'
    'ops/prod/ops_project'
    'ops/prod/ops_gke'
    'ops/prod/ops_lb'
    'ops/prod/cloudbuild'
    'ops/prod/istio_prep'
    'ops/prod/k8s_repo'
    'apps/prod/app1/app1_project'
    'apps/prod/app1/app1_gke'
    'apps/prod/app1/app1_gce'
    'apps/prod/app2/app2_project'
    'apps/prod/app2/app2_gke'
    )

# Build backends and shared states for each GCP prod resource
for idx in ${!folders[@]}
do
    # Extract the resource name from the folder
    resource=$(echo ${folders[idx]} | grep -oP '([^\/]+$)')

    # Create backends
    sed -e s/PROJECT_ID/${TF_ADMIN}/ -e s/ENV/prod/ -e s/RESOURCE/${resource}/ \
    infrastructure/templates/backend.tf_tmpl > infrastructure/${folders[idx]}/backend.tf

    # Create shared states for every resource
    sed -e s/PROJECT_ID/${TF_ADMIN}/ -e s/RESOURCE/${resource}/ \
    infrastructure/templates/shared_state.tf_tmpl > infrastructure/gcp/prod/shared_states/shared_state_${resource}.tf

    # Create vars from terraform.tfvars_tmpl files
    tfvar_tmpl_file=infrastructure/${folders[idx]}/terraform.tfvars_tmpl
    if [ -f "$tfvar_tmpl_file" ]; then
        envsubst <infrastructure/${folders[idx]}/terraform.tfvars_tmpl \
        > infrastructure/${folders[idx]}/terraform.tfvars
    fi

    # Create vars from variables.auto.tfvars_tmpl files
    auto_tfvar_tmpl_file=infrastructure/${folders[idx]}/variables.auto.tfvars_tmpl
    if [ -f "$auto_tfvar_tmpl_file" ]; then
        envsubst <infrastructure/${folders[idx]}/variables.auto.tfvars_tmpl \
        > infrastructure/${folders[idx]}/variables.auto.tfvars
    fi

done

echo -e "\n${CYAN}Committing infrastructure terraform to cloud source repo...${NC}"
cd ./infrastructure
git config --local user.email ${TF_CLOUDBUILD_SA}
git config --local user.name "terraform"
git config --local credential.'https://source.developers.google.com'.helper gcloud.sh
git init
git remote add infra "https://source.developers.google.com/p/${TF_ADMIN}/r/infrastructure"
git add . && git commit -am "first commit"
git push infra master
cd ..

