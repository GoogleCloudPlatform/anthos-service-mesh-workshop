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

. ./scripts/functions.sh

# Lab 1 Deploy the Sample App

# Set speed
SPEED=60
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
echo "${bold}*** Lab 1: Deploy the Sample App ***${normal}"
echo -e "\n"

# Set up ops git repo
echo "${bold}Set up ops git repo if not already done${normal}"
read -p ''
print_and_execute "mkdir -p ${WORKDIR}/k8s-repo"
print_and_execute "cd ${WORKDIR}/k8s-repo"

git remote -v &>/dev/null
if [[ $? -ne 0 ]]; then
  print_and_execute "git init && git remote add origin https://source.developers.google.com/p/${TF_VAR_ops_project_name}/r/k8s-repo"
  print_and_execute "git config --local user.email ${MY_USER} && git config --local user.name \"K8s repo user\""
  print_and_execute "git config --local credential.'https://source.developers.google.com'.helper gcloud.sh"
  print_and_execute "git fetch origin"
else
  echo "git repo already initialized."
fi

## Copy manifests to source repo
#echo -e "\n"
#echo "${bold}Copy the Hipster Shop namespaces and services to the source repo for all clusters${normal}"
#read -p ''
print_and_execute "cd ${WORKDIR}/asm"
#print_and_execute "cp -r k8s_manifests/prod/app/namespaces ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/namespaces ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/namespaces ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/namespaces ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/namespaces ../k8s-repo/${OPS_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/namespaces ../k8s-repo/${OPS_GKE_2_CLUSTER}/app/"
#echo -e "\n"
#print_and_execute "cp -r k8s_manifests/prod/app/services ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/services ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/services ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/services ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/services ../k8s-repo/${OPS_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/services ../k8s-repo/${OPS_GKE_2_CLUSTER}/app/"
#
#echo -e "\n"
#echo "${bold}Copy the Hipster Shop deployments, rbac and psp to the source repo for dev clusters${normal}"
#read -p ''
#print_and_execute "cp -r k8s_manifests/prod/app/deployments ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/deployments ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/deployments ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/deployments ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
#echo -e "\n"
#print_and_execute "cp -r k8s_manifests/prod/app/rbac ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/rbac ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/rbac ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/rbac ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
#echo -e "\n"
#print_and_execute "cp -r k8s_manifests/prod/app/podsecuritypolicies ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/podsecuritypolicies ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/podsecuritypolicies ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/"
#print_and_execute "cp -r k8s_manifests/prod/app/podsecuritypolicies ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/"
#
#echo -e "\n"
#echo "${bold}Remove podsecuritypolicies, deployments and rbac directories from ops clusters kustomization.yaml${normal}"
#read -p ''
#print_and_execute "sed -i -e '/- deployments\//d' -e '/- podsecuritypolicies\//d'  -e '/- rbac\//d' ../k8s-repo/${OPS_GKE_1_CLUSTER}/app/kustomization.yaml"
#print_and_execute "sed -i -e '/- deployments\//d' -e '/- podsecuritypolicies\//d'  -e '/- rbac\//d' ../k8s-repo/${OPS_GKE_2_CLUSTER}/app/kustomization.yaml"
#
#echo -e "\n"
#echo "${bold}Remove cartservice from all but one dev cluster ${normal}"
#read -p ''
#print_and_execute "rm ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/deployments/app-cart-service.yaml"
#print_and_execute "rm ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/podsecuritypolicies/cart-psp.yaml"
#print_and_execute "rm ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/rbac/cart-rbac.yaml"
#echo -e "\n"
#print_and_execute "rm ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/deployments/app-cart-service.yaml"
#print_and_execute "rm ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/podsecuritypolicies/cart-psp.yaml"
#print_and_execute "rm ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/rbac/cart-rbac.yaml"
#echo -e "\n"
#print_and_execute "rm ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/deployments/app-cart-service.yaml"
#print_and_execute "rm ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/podsecuritypolicies/cart-psp.yaml"
#print_and_execute "rm ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/rbac/cart-rbac.yaml"
#
#echo -e "\n"
#echo "${bold}Add cartservice deployment, rbac and podsecuritypolicy to kustomization.yaml in the first dev cluster only${normal}"
#read -p ''
#print_and_execute "cd ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app"
#print_and_execute "cd deployments && kustomize edit add resource app-cart-service.yaml"
#print_and_execute "cd ../podsecuritypolicies && kustomize edit add resource cart-psp.yaml"
#print_and_execute "cd ../rbac && kustomize edit add resource cart-rbac.yaml"
#print_and_execute "cd ${WORKDIR}/asm"
#
#echo -e "\n"
#echo "${bold}Replace the PROJECT_ID in the RBAC manifests.${normal}"
#read -p ''
#print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev1_project_name}'/g'  ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app/rbac/*"
#print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev1_project_name}'/g'  ../k8s-repo/${DEV1_GKE_2_CLUSTER}/app/rbac/*"
#print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev2_project_name}'/g'  ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app/rbac/*"
#print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev2_project_name}'/g'  ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/rbac/*"
#
#echo -e "\n"
#echo "${bold}Copy the IngressGateway and VirtualService manifests to the source repo for the ops clusters.${normal}"
#read -p ''
#print_and_execute "cp -r k8s_manifests/prod/app-ingress/* ../k8s-repo/${OPS_GKE_1_CLUSTER}/app-ingress/"
#print_and_execute "cp -r k8s_manifests/prod/app-ingress/* ../k8s-repo/${OPS_GKE_2_CLUSTER}/app-ingress/"
#
#echo -e "\n"
#echo "${bold}Copy the Config Connector resources to one of clusters in each project.${normal}"
#read -p ''
#print_and_execute "cp -r k8s_manifests/prod/app-cnrm/* ../k8s-repo/${OPS_GKE_1_CLUSTER}/app-cnrm/"
#print_and_execute "cp -r k8s_manifests/prod/app-cnrm/* ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app-cnrm/"
#print_and_execute "cp -r k8s_manifests/prod/app-cnrm/* ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app-cnrm/"
#
#echo -e "\n"
#echo "${bold}Replace the PROJECT_ID in the Config Connector manifests.${normal}"
#read -p ''
#print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_ops_project_name}'/g' ../k8s-repo/${OPS_GKE_1_CLUSTER}/app-cnrm/*"
#print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev1_project_name}'/g'  ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app-cnrm/*"
#print_and_execute "sed -i 's/\${PROJECT_ID}/'${TF_VAR_dev2_project_name}'/g'  ../k8s-repo/${DEV2_GKE_1_CLUSTER}/app-cnrm/*"
#
#echo -e "\n"
#echo "${bold}Copy loadgenerator manifests (Deployment, PodSecurityPolicy and RBAC) to the ops clusters.${normal}"
#read -p ''
#print_and_execute "cp -r k8s_manifests/prod/app-loadgenerator/. ../k8s-repo/gke-asm-1-r1-prod/app-loadgenerator/."
#print_and_execute "cp -r k8s_manifests/prod/app-loadgenerator/. ../k8s-repo/gke-asm-2-r2-prod/app-loadgenerator/."
#
#echo -e "\n"
#echo "${bold}Replace the ops project ID in the loadgenerator manifests for both ops clusters.${normal}"
#read -p ''
#print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ../k8s-repo/${OPS_GKE_1_CLUSTER}/app-loadgenerator/loadgenerator-deployment.yaml"
#print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ../k8s-repo/${OPS_GKE_1_CLUSTER}/app-loadgenerator/loadgenerator-rbac.yaml"
#print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ../k8s-repo/${OPS_GKE_2_CLUSTER}/app-loadgenerator/loadgenerator-deployment.yaml"
#print_and_execute "sed -i 's/OPS_PROJECT_ID/'${TF_VAR_ops_project_name}'/g'  ../k8s-repo/${OPS_GKE_2_CLUSTER}/app-loadgenerator/loadgenerator-rbac.yaml"
#
#echo -e "\n"
#echo "${bold}Add the loadgenerator resources to kustomization.yaml for both ops clusters.${normal}"
#read -p ''
#print_and_execute "cd ../k8s-repo/${OPS_GKE_1_CLUSTER}/app-loadgenerator/"
#print_and_execute "kustomize edit add resource loadgenerator-psp.yaml"
#print_and_execute "kustomize edit add resource loadgenerator-rbac.yaml"
#print_and_execute "kustomize edit add resource loadgenerator-deployment.yaml"
#print_and_execute "cd ../../${OPS_GKE_2_CLUSTER}/app-loadgenerator/"
#print_and_execute "kustomize edit add resource loadgenerator-psp.yaml"
#print_and_execute "kustomize edit add resource loadgenerator-rbac.yaml"
#print_and_execute "kustomize edit add resource loadgenerator-deployment.yaml"
#

cp k8s_manifests/prod/app/podsecuritypolicies/ad-psp.yaml ../k8s-repo/${DEV2_GKE_2_CLUSTER}/app/podsecuritypolicies/ad-psp3.yaml

echo -e "\n"
echo "${bold}View changes to k8s-repo.${normal}"
read -p ''
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute "git status"

echo -e "\n"
echo "${bold}Commit to k8s-repo to trigger deployment.${normal}"
read -p ''
print_and_execute "git add . && git commit -am \"create app namespaces and install hipster shop\""
print_and_execute "git push"

echo -e "\n"
echo "${bold}Wait for Cloud Build to finish.${normal}"
read -p ''

BUILD_STATUS=${gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --format="value(status)"}
while [[ "${BUILD_STATUS}" == "WORKING" ]]
  do
      echo -e "Still waiting for cloud build to finish. Sleeping for 10s"
      sleep 10
      BUILD_STATUS=${gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --format="value(status)"}
  done

echo -e "\n"
echo "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  echo "Build unsuccessful. Check build logs at https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}.\n Exiting...."
  exit
fi

echo -e "\n"
echo "${bold}Verify pods in all application namespaces except cart are in Running state in all dev clusters.${normal}"
read -p ''

for ns in ad checkout currency email frontend payment product-catalog recommendation shipping; do
  print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n ${ns}"
  print_and_execute "kubectl --context ${DEV1_GKE_2} get pods -n ${ns}"
  print_and_execute "kubectl --context ${DEV2_GKE_1} get pods -n ${ns}"
  print_and_execute "kubectl --context ${DEV2_GKE_2} get pods -n ${ns}"
done;

echo -e "\n"
echo "${bold}Verify pods in cart namespace are in Running state in first dev cluster only. ${normal}"
read -p ''
print_and_execute "kubectl --context ${DEV1_GKE_1} get pods -n cart"

echo -e "\n"
echo "${bold}Access the Hipster shop.${normal}"
read -p ''
echo "Go to the link below to access Hipster shop."
echo "https://frontend.endpoints.${TF_VAR_ops_project_name}.cloud.goog"
