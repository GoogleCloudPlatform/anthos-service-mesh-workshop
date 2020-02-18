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



 
