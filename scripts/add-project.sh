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

PROJECT_NAME=$1
SRC_DIR=$2
DEST_DIR=$3

[[ $# -ne 3 ]] && echo "USAGE: $0 <project name> <src dir> <dest dir>" && exit 1

[[ ! -e "${SRC_DIR}/vars/vars.sh" ]] && echo "Missing vars.sh in src dir: ${SRC_DIR}/vars/vars.sh" && exit 1

PROJECT_DIR="${DEST_DIR}/apps/prod/${PROJECT_NAME}/${PROJECT_NAME}_project"
PROJECT_GKE_DIR="${DEST_DIR}/apps/prod/${PROJECT_NAME}/${PROJECT_NAME}_gke"
[[ ! -d ${PROJECT_DIR} ]] && echo "Missing project directory: ${PROJECT_DIR}" && exit 1
[[ ! -d ${PROJECT_GKE_DIR} ]] && echo "Missing project GKE directory: ${PROJECT_GKE_DIR}" && exit 1

# Font colors
export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color

# Create a vars folder and file
export VARS_FILE=${SRC_DIR}/vars/vars.sh
source ${VARS_FILE}

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SRC_DIR}/logs
export LOG_FILE=${SRC_DIR}/logs/add-project-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

echo -e "\n${CYAN}Preparing terraform backends, shared states and vars...${NC}"
# Define an array of GCP resources
declare -a folders
folders=(
    ${PROJECT_DIR}
    ${PROJECT_GKE_DIR}
    )

# Build backends and shared states for each GCP prod resource
for idx in ${!folders[@]}
do
    # Extract the resource name from the folder
    resource=$(echo ${folders[idx]} | grep -oP '([^\/]+$)')

    # Create backends
    sed -e s/PROJECT_ID/${TF_ADMIN}/ -e s/ENV/prod/ -e s/RESOURCE/${resource}/ \
    ${SRC_DIR}/infrastructure/templates/backend.tf_tmpl > ${folders[idx]}/backend.tf

    # Create shared states for every resource
    sed -e s/PROJECT_ID/${TF_ADMIN}/ -e s/RESOURCE/${resource}/ \
    ${SRC_DIR}/infrastructure/templates/shared_state.tf_tmpl > ${DEST_DIR}/gcp/prod/shared_states/shared_state_${resource}.tf

    # Create vars from terraform.tfvars_tmpl files
    tfvar_tmpl_file=${folders[idx]}/terraform.tfvars_tmpl
    if [ -f "$tfvar_tmpl_file" ]; then
        envsubst <${folders[idx]}/terraform.tfvars_tmpl \
        > ${folders[idx]}/terraform.tfvars
    fi

    # Create vars from variables.auto.tfvars_tmpl files
    auto_tfvar_tmpl_file=${folders[idx]}/variables.auto.tfvars_tmpl
    if [ -f "$auto_tfvar_tmpl_file" ]; then
        envsubst <${folders[idx]}/variables.auto.tfvars_tmpl \
        > ${folders[idx]}/variables.auto.tfvars
    fi

done
