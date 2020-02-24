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
export LAB_NAME=authorization-policy

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Authorization Policy

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
echo "${bold}*** Lab: Authorization Policy ***${normal}"
echo -e "\n"

# https://codelabs.developers.google.com/codelabs/anthos-service-mesh-workshop/#9
title_no_wait "Objective:  Set up RBAC between microservices (AuthZ)."
title_no_wait "  1. Create AuthorizationPolicy to DENY access to a microservice"
title_no_wait "  2. Create AuthorizationPolicy to ALLOW specific access to a microservice"
echo -e "\n"

title_no_wait "Inspect the contents of \"currency-deny-all.yaml\"." 
title_no_wait "This policy uses Deployment label selectors to restrict access to the currencyservice." 
title_and_wait "Notice how there is no spec field - this means this policy will DENY all access to the selected service."

print_and_execute "cat ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-deny-all.yaml"
title_and_wait ""



