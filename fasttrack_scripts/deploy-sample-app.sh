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

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-deploy-sample-app-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab 1 Deploy the Sample App

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
title_no_wait "*** Lab: Deploy the Sample App ***"
echo -e "\n"

source ${HOME}/.bashrc

# Set up ops git repo
title_and_wait "Set up ops git repo if not already done."
print_and_execute "mkdir -p ${WORKDIR}/k8s-repo"
print_and_execute "cd ${WORKDIR}/k8s-repo"

git remote -v &>/dev/null
if [[ $? -ne 0 ]]; then
  print_and_execute "git init && git remote add origin https://source.developers.google.com/p/${TF_VAR_ops_project_name}/r/k8s-repo"
  print_and_execute "git config --local user.email ${MY_USER} && git config --local user.name \"K8s repo user\""
  print_and_execute "git config --local credential.'https://source.developers.google.com'.helper gcloud.sh"
  print_and_execute "git pull origin master"
  if [[ $? -eq 0 ]]; then
    title_no_wait "git repo successfully pulled!"
  else
    error_no_wait "Error pulling git repo. Please inspect the repo name and make sure it is formatted properly."
    error_no_wait "Deleting the k8s-repo folder..."
    print_and_execute "rm -rf ${WORKDIR}/k8s-repo"
    error_no_wait "Exiting script... "
    exit 1
  fi
else
  title_no_wait "git repo already initialized."
fi

# Copy manifests to source repo
echo -e "\n"
title_and_wait "Copy the Hipster Shop namespaces and services to the source repo for all clusters."
print_and_execute "cd ${WORKDIR}/asm"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/namespaces ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/namespaces ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/namespaces ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/namespaces ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/namespaces ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/namespaces ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app/"
echo -e "\n"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/services ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/services ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/services ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/services ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/services ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/services ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app/"

echo -e "\n"
title_and_wait "Copy the app folder kustomization.yaml to all clusters."
print_and_execute "cd ${WORKDIR}/asm"
print_and_execute "cp ${SCRIPT_DIR}/../k8s_manifests/prod/app/kustomization.yaml ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
print_and_execute "cp ${SCRIPT_DIR}/../k8s_manifests/prod/app/kustomization.yaml ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
print_and_execute "cp ${SCRIPT_DIR}/../k8s_manifests/prod/app/kustomization.yaml ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
print_and_execute "cp ${SCRIPT_DIR}/../k8s_manifests/prod/app/kustomization.yaml ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
print_and_execute "cp ${SCRIPT_DIR}/../k8s_manifests/prod/app/kustomization.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app/"
print_and_execute "cp ${SCRIPT_DIR}/../k8s_manifests/prod/app/kustomization.yaml ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app/"


echo -e "\n"
title_and_wait "Copy the Hipster Shop Deployments, RBAC and PodSecurityPolicy to the source repo for the apps clusters."
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/deployments ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/deployments ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/deployments ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/deployments ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
echo -e "\n"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/rbac ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/rbac ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/rbac ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/rbac ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
echo -e "\n"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/podsecuritypolicies ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/podsecuritypolicies ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/podsecuritypolicies ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app/podsecuritypolicies ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"

echo -e "\n"
title_and_wait "Remove PodSecurityPolicies, Deployments and RBAC directories from ops clusters kustomization.yaml."
print_and_execute "sed -i -e '/- deployments\//d' -e '/- podsecuritypolicies\//d'  -e '/- rbac\//d' ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app/kustomization.yaml"
print_and_execute "sed -i -e '/- deployments\//d' -e '/- podsecuritypolicies\//d'  -e '/- rbac\//d' ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app/kustomization.yaml"

echo -e "\n"
title_and_wait "Remove cartservice from all but app-1 cluster."
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/deployments/app-cart-service.yaml"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/podsecuritypolicies/cart-psp.yaml"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/rbac/cart-rbac.yaml"
echo -e "\n"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/deployments/app-cart-service.yaml"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/podsecuritypolicies/cart-psp.yaml"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/rbac/cart-rbac.yaml"
echo -e "\n"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/deployments/app-cart-service.yaml"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/podsecuritypolicies/cart-psp.yaml"
print_and_execute "rm ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/rbac/cart-rbac.yaml"

echo -e "\n"
title_and_wait "Add cartservice Deployment, RBAC and PodSecurityPolicy to kustomization.yaml in the app-1 cluster only."
print_and_execute "cd ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app"
print_and_execute "cd deployments && kustomize edit add resource app-cart-service.yaml"
print_and_execute "cd ../podsecuritypolicies && kustomize edit add resource cart-psp.yaml"
print_and_execute "cd ../rbac && kustomize edit add resource cart-rbac.yaml"
print_and_execute "cd ${WORKDIR}/asm"

echo -e "\n"
title_and_wait "Populate the PROJECT_IDs in the apps clusters' RBAC manifests."
print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev1_project_name}'/g'  ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/rbac/*"
print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev1_project_name}'/g'  ${WORKDIR}/k8s-repo/${DEV1_GKE_2_CLUSTER}/app/rbac/*"
print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev2_project_name}'/g'  ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app/rbac/*"
print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev2_project_name}'/g'  ${WORKDIR}/k8s-repo/${DEV2_GKE_2_CLUSTER}/app/rbac/*"

echo -e "\n"
title_and_wait "Copy the IngressGateway and VirtualService manifests to the source repo for the ops clusters."
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app-ingress/* ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-ingress/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app-ingress/* ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-ingress/"

echo -e "\n"
title_and_wait "Copy the Config Connector resources to one of clusters in each project."
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app-cnrm/* ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-cnrm/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app-cnrm/* ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app-cnrm/"
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app-cnrm/* ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app-cnrm/"

echo -e "\n"
title_and_wait "Populate the PROJECT_IDs in the Config Connector manifests."
print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_ops_project_name}'/g' ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-cnrm/*"
print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev1_project_name}'/g'  ${WORKDIR}/k8s-repo/${DEV1_GKE_1_CLUSTER}/app-cnrm/*"
print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev2_project_name}'/g'  ${WORKDIR}/k8s-repo/${DEV2_GKE_1_CLUSTER}/app-cnrm/*"

echo -e "\n"
title_and_wait "Copy loadgenerator manifests (Deployment, PodSecurityPolicy and RBAC) to the ops clusters."
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app-loadgenerator/. ${WORKDIR}/k8s-repo/gke-asm-1-r1-prod/app-loadgenerator/."
print_and_execute "cp -r ${SCRIPT_DIR}/../k8s_manifests/prod/app-loadgenerator/. ${WORKDIR}/k8s-repo/gke-asm-2-r2-prod/app-loadgenerator/."

echo -e "\n"
title_and_wait "Replace the ops project ID in the loadgenerator manifests for both ops clusters."
print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-loadgenerator/loadgenerator-deployment.yaml"
print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-loadgenerator/loadgenerator-rbac.yaml"
print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-loadgenerator/loadgenerator-deployment.yaml"
print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-loadgenerator/loadgenerator-rbac.yaml"

echo -e "\n"
title_and_wait "Add the loadgenerator resources to kustomization.yaml for both ops clusters."
print_and_execute "cd ${WORKDIR}/k8s-repo/${OPS_GKE_1_CLUSTER}/app-loadgenerator/"
print_and_execute "kustomize edit add resource loadgenerator-psp.yaml"
print_and_execute "kustomize edit add resource loadgenerator-rbac.yaml"
print_and_execute "kustomize edit add resource loadgenerator-deployment.yaml"
print_and_execute "cd ${WORKDIR}/k8s-repo/${OPS_GKE_2_CLUSTER}/app-loadgenerator/"
print_and_execute "kustomize edit add resource loadgenerator-psp.yaml"
print_and_execute "kustomize edit add resource loadgenerator-rbac.yaml"
print_and_execute "kustomize edit add resource loadgenerator-deployment.yaml"


echo -e "\n"
title_and_wait "View changes to k8s-repo."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute "git status"
echo -e "\n"

echo -e "\n"
title_and_wait "Commit to k8s-repo to trigger deployment."
print_and_execute "git add . && git commit -am \"create app namespaces and install hipster shop\""
print_and_execute "git push --set-upstream origin master"

echo -e "\n"
title_no_wait "View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
title_no_wait "Waiting for Cloud Build to finish..."

BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
while [[ "${BUILD_STATUS}" =~ WORKING|QUEUED ]]
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

echo -e "\n"
title_and_wait "Verify pods in all application namespaces except cart are in Running state in all apps clusters."

for ns in ad checkout currency email payment recommendation shipping; do
  # print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV1_GKE_2} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV2_GKE_1} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV2_GKE_2} get pods -n ${ns}"
  title_no_wait "Waiting until Deployment ${ns}service is deployed and Ready in all app clusters..."
  is_deployment_ready ${DEV1_GKE_1} ${ns} ${ns}service
  is_deployment_ready ${DEV1_GKE_2} ${ns} ${ns}service
  is_deployment_ready ${DEV2_GKE_1} ${ns} ${ns}service
  is_deployment_ready ${DEV2_GKE_2} ${ns} ${ns}service
  echo -e "\n"
done;

for ns in frontend loadgenerator; do
  # print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV1_GKE_2} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV2_GKE_1} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV2_GKE_2} get pods -n ${ns}"
  title_no_wait "Waiting until Deployment ${ns} is deployed and Ready in all app clusters..."
  is_deployment_ready ${DEV1_GKE_1} ${ns} ${ns}
  is_deployment_ready ${DEV1_GKE_2} ${ns} ${ns}
  is_deployment_ready ${DEV2_GKE_1} ${ns} ${ns}
  is_deployment_ready ${DEV2_GKE_2} ${ns} ${ns}
  echo -e "\n"
done;

for svc in productcatalogservice; do
  # print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV1_GKE_2} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV2_GKE_1} get pods -n ${ns}"
  # print_and_execute "kubectl --context ${DEV2_GKE_2} get pods -n ${ns}"
  title_no_wait "Waiting until Deployment ${svc} is deployed and Ready in all app clusters..."
  is_deployment_ready ${DEV1_GKE_1} product-catalog ${svc}
  is_deployment_ready ${DEV1_GKE_2} product-catalog ${svc}
  is_deployment_ready ${DEV1_GKE_2} product-catalog ${svc}
  is_deployment_ready ${DEV2_GKE_2} product-catalog ${svc}
  echo -e "\n"
done;

echo -e "\n"
title_and_wait "Verify pods in cart namespace are in Running state in app-1 cluster only."
# print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n cart"
is_deployment_ready ${DEV1_GKE_1} cart cartservice

echo -e "\n"
title_no_wait "Access the Hipster shop."
title_no_wait "Go to the link below to access Hipster shop."
title_no_wait "https://frontend.endpoints.${TF_VAR_ops_project_name}.cloud.goog"

title_no_wait "Congratulations! You have successfully completed the Deploy Sample Application lab."
echo -e "\n"
