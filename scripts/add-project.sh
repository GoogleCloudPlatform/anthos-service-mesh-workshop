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

SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")

# TASK: Add new project script

# Font colors
export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color


# Create a vars folder and file
export VARS_FILE=${SCRIPT_DIR}/../vars/vars.sh
source ${VARS_FILE}

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/add-project-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

echo -e "\n${CYAN}Preparing terraform backends, shared states and vars...${NC}"
# Define an array of GCP resources
declare -a folders
folders=(
    'apps/prod/app3/app3_project'
    'apps/prod/app3/app3_gke'
    )

# Build backends and shared states for each GCP prod resource
for idx in ${!folders[@]}
do
    # Extract the resource name from the folder
    resource=$(echo ${folders[idx]} | grep -oP '([^\/]+$)')

    # Create backends
    sed -e s/PROJECT_ID/${TF_ADMIN}/ -e s/ENV/prod/ -e s/RESOURCE/${resource}/ \
    ${SCRIPT_DIR}/../infrastructure/templates/backend.tf_tmpl > ${SCRIPT_DIR}/../../infra-repo/${folders[idx]}/backend.tf

    # Create shared states for every resource
    sed -e s/PROJECT_ID/${TF_ADMIN}/ -e s/RESOURCE/${resource}/ \
    ${SCRIPT_DIR}/../infrastructure/templates/shared_state.tf_tmpl > ${SCRIPT_DIR}/../../infra-repo/gcp/prod/shared_states/shared_state_${resource}.tf

    # Create vars from terraform.tfvars_tmpl files
    tfvar_tmpl_file=${SCRIPT_DIR}/../../infra-repo/${folders[idx]}/terraform.tfvars_tmpl
    if [ -f "$tfvar_tmpl_file" ]; then
        envsubst <${SCRIPT_DIR}/../../infra-repo/${folders[idx]}/terraform.tfvars_tmpl \
        > ${SCRIPT_DIR}/../../infra-repo/${folders[idx]}/terraform.tfvars
    fi

    # Create vars from variables.auto.tfvars_tmpl files
    auto_tfvar_tmpl_file=${SCRIPT_DIR}/../../infra-repo/${folders[idx]}/variables.auto.tfvars_tmpl
    if [ -f "$auto_tfvar_tmpl_file" ]; then
        envsubst <${SCRIPT_DIR}/../../infra-repo/${folders[idx]}/variables.auto.tfvars_tmpl \
        > ${SCRIPT_DIR}/../../infra-repo/${folders[idx]}/variables.auto.tfvars
    fi

done

echo -e "\n${CYAN}Committing infrastructure terraform to cloud source repo...${NC}"
cd ${SCRIPT_DIR}/../../infra-repo
git config --local user.email ${MY_USER} && git config --local user.name "infra repo user"
git add . && git commit -am "add new project"
git push --set-upstream origin master
