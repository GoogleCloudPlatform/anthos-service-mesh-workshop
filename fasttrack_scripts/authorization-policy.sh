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
echo -e "\n"

title_and_wait "Copy the currency policy into k8s-repo, for the ops clusters both regions. Add the new resource to the kustomization.yaml files."

title_no_wait "For ${OPS_GKE_1_CLUSTER} cluster:"
print_and_execute "cp ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-deny-all.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cd ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-authorization"
print_and_execute "kustomize edit add resource currency-policy.yaml"

title_no_wait "For ${OPS_GKE_2_CLUSTER} cluster:"
print_and_execute "cp ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-deny-all.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cd ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-authorization"
print_and_execute "kustomize edit add resource currency-policy.yaml"

echo -e "\n"
title_and_wait "Commit to k8s-repo to trigger deployment."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute "git add . && git commit -am \"AuthorizationPolicy - currency: deny all\""
print_and_execute "git push --set-upstream origin master"

echo -e "\n"
title_no_wait "View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
title_no_wait "Waiting for Cloud Build to finish..."

BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
while [[ "${BUILD_STATUS}" == "WORKING" ]]
  do
      title_no_wait "Still waiting for cloud build to finish. Sleep for 10s"
      sleep 10
      BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
  done

echo -e "\n"
title_no_wait "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}. \n Exiting...."
  exit 1
fi

title_no_wait "Try to access the Hipster shop by clicking the following link."
print_and_execute "echo \"https://frontend.endpoints.${TF_VAR_ops_project_name}.cloud.goog\""
title_and_wait "You should see an Authorization error (RBAC: access denied) from currencyservice."

title_no_wait "Verify the currency service is enforcing this AuthorizationPolicy."
title_and_wait "Enable trace-level logs on the Envoy proxy for one of the currency pods. Blocked authorization calls aren't logged by default."
print_and_execute "CURRENCY_POD=$(kubectl --context ${DEV1_GKE_2} get pod -n currency | grep currency| awk '{ print $1 }')"
print_and_execute "kubectl --context ${DEV1_GKE_2} exec -it ${CURRENCY_POD} -n currency -c istio-proxy -- curl -X POST \"http://localhost:15000/logging?level=trace\""
title_and_wait "Get the RBAC (authorization) logs from the currency service's sidecar proxy."
print_and_execute "kubectl --context ${DEV1_GKE_2} logs -n currency ${CURRENCY_POD} -c istio-proxy | grep -m 3 rbac"
title_and_wait "You see an \"enforced denied\" message, indicating that the currencyservice is set to block all inbound requests."

title_no_wait "Allow only the \"frontend\" service to access the currencyservice."
title_and_wait "Inspect the \"currency-allow-frontend.yaml\"."
print_and_execute "cat ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-allow-frontend.yaml"
echo -e "\n"

title_no_wait "This AuthorizationPolicy whitelists a specific source.principal (client) to access currency service." 
title_no_wait "This source.principal is defined by is Kubernetes Service Account (in this case frontend KSA in the frontend namespace)." 
title_no_wait "Mutual TLS (mTLS) must be enabled cluster-wide in order to use Kubernetes Service Accounts in Istio AuthorizationPolicies."
title_and_wait "This ensures that service account credentials are mounted into requests."
print_and_execute "cp ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-allow-frontend.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cp ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-allow-frontend.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-authorization/currency-policy.yaml"
 
echo -e "\n"
title_and_wait "Commit to k8s-repo to trigger deployment."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute "git add . && git commit -am \"AuthorizationPolicy - currency: allow frontend\""
print_and_execute "git push --set-upstream origin master"

echo -e "\n"
title_no_wait "View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
title_no_wait "Waiting for Cloud Build to finish..."

BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
while [[ "${BUILD_STATUS}" == "WORKING" ]]
  do
      title_no_wait "Still waiting for cloud build to finish. Sleep for 10s"
      sleep 10
      BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
  done

echo -e "\n"
title_no_wait "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}. \n Exiting...."
  exit 1
fi

title_no_wait "Access the Hipster shop by clicking the following link."
print_and_execute "echo \"https://frontend.endpoints.${TF_VAR_ops_project_name}.cloud.goog\""
title_and_wait "You see no errors accessing the frontend of the Hipster shop."

title_no_wait "Perform a checkout."
title_no_wait "From the Hipster shop app tab, Add an item (or more) to the shopping cart."
title_and_wait "Click on the cart and click on \"Place order\" from the cart page."

title_no_wait "Upon checkout, you see a \"failed to convert price\" error."
title_no_wait "Frontend service is authorized to access checkout service."
title_no_wait "However, checkout service still cannot access the currency service."
title_no_wait "This is required to perform a checkout."
echo -e "\n"

title_no_wait "Authorize checkout service to access currency service."
title_and_wait "Inspect the \"currency-allow-frontend-checlout.yaml\"."
print_and_execute "cat ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-allow-frontend-checkout.yaml"
echo -e "\n"


title_no_wait "The AuthorizationPolicy allows currency service access from both the frontend and the checkout service ."

title_and_wait "Copy this AuthorizationPolicy to k8s-repo.."
print_and_execute "cp ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-allow-frontend-checkout.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cp ${WORKDIR}/asm/k8s_manifests/prod/app-authorization/currency-allow-frontend-checkout.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-authorization/currency-policy.yaml"
 
echo -e "\n"
title_and_wait "Commit to k8s-repo to trigger deployment."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute "git add . && git commit -am \"AuthorizationPolicy - currency: allow frontend and checkout\""
print_and_execute "git push --set-upstream origin master"

echo -e "\n"
title_no_wait "View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
title_no_wait "Waiting for Cloud Build to finish..."

BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
while [[ "${BUILD_STATUS}" == "WORKING" ]]
  do
      title_no_wait "Still waiting for cloud build to finish. Sleep for 10s"
      sleep 10
      BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
  done

echo -e "\n"
title_no_wait "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}. \n Exiting...."
  exit 1
fi

title_no_wait "Access the Hipster shop by clicking the following link."
print_and_execute "echo \"https://frontend.endpoints.${TF_VAR_ops_project_name}.cloud.goog\""
title_and_wait "You see no errors accessing the frontend of the Hipster shop."

title_no_wait "Perform a checkout."
title_no_wait "From the Hipster shop app tab, Add an item (or more) to the shopping cart."
title_and_wait "Click on the cart and click on \"Place order\" from the cart page."

title_no_wait "You can successfully access the Hipster shop and perform a checklout."
echo -e "\n"

title_no_wait "Congratulations! You have successfully completed the Authorization Policies lab."
echo -e "\n"





