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
print_and_execute "mkdir -p ${HOME}/bin && cd ${HOME}/bin"
print_and_execute "curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash"
print_and_execute "export PATH=$PATH:${HOME}/bin"
print_and_execute "echo "export PATH=$PATH:${HOME}/bin" >> ~/.bashrc"
echo -e "\n"
print_and_execute "sudo apt-get update && sudo apt-get -y install pv"
print_and_execute "echo -e  '#!/bin/sh' >> $HOME/.customize_environment"
print_and_execute "echo -e "apt-get update" >> $HOME/.customize_environment"
print_and_execute "echo -e "apt-get -y install pv" >> $HOME/.customize_environment"
echo -e "\n"


 
