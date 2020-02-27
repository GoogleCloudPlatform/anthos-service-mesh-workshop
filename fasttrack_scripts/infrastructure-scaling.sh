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
export LAB_NAME=infrastructure-scaling

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Infrastructure Scaling

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
echo "${bold}*** Lab: Infrastructure Scaling ***${normal}"
echo -e "\n"

title_and_wait "Clone the infrastructure repo from Cloud Source Repositories"
print_and_execute "cd ${WORKDIR} && mkdir -p ${WORKDIR}/infra-repo && cd ${WORKDIR}/infra-repo && git init && git remote add origin https://source.developers.google.com/p/${TF_ADMIN}/r/infrastructure"

print_and_execute "(cd ${WORKDIR}/infra-repo && git config --local user.email ${MY_USER} && git config --local user.name \"infra repo user\")"
print_and_execute "(cd ${WORKDIR}/infra-repo && git config --local credential.'https://source.developers.google.com'.helper gcloud.sh)"
print_and_execute "(cd ${WORKDIR}/infra-repo && git pull origin master)"

title_and_wait "Clone the workshop source repo 'add-proj' branch into the 'add-proj-repo' directory"
rm -rf ${WORKDIR}/add-proj-repo
print_and_execute "(cd ${WORKDIR} && git clone https://github.com/GoogleCloudPlatform/anthos-service-mesh-workshop.git add-proj-repo -b add-proj)"

title_and_wait "Copy files from the add-proj branch in the source workshop repo. The add-proj branch contains the changes for this section."
print_and_execute "(cd ${WORKDIR}/add-proj-repo && cp -R infrastructure/* ${WORKDIR}/infra-repo/)"

title_and_wait "Replace the infrastructure directory in the add-proj repo directory with a symlink to the infra-repo directory to allow the scripts on the branch to run."
print_and_execute "(cd ${WORKDIR}/add-proj-repo && rm -rf infrastructure && ln -s ${WORKDIR}/infra-repo infrastructure)"

title_and_wait "Run the add-project.sh script to copy the shared states and vars to the new project directory structure."
print_and_execute "${WORKDIR}/add-proj-repo/scripts/add-project.sh app3 ${WORKDIR}/asm ${WORKDIR}/infra-repo"

print_and_execute "(cd ${WORKDIR}/infra-repo && git add . && git status)"
title_and_wait "Commit and push changes to create new project"
print_and_execute "(cd ${WORKDIR}/infra-repo && git commit -m \"add new project\" && git push origin master)"

echo -e "\n"
title_no_wait "View the status of the TF project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_ADMIN}"
title_no_wait "This step takes 25-30 mins. This is a good time for a coffee break."
title_no_wait "Waiting for Cloud Build to finish..."

BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_ADMIN} --format="value(id)" | head -n 1) --project ${TF_ADMIN} --format="value(status)")
while [[ "${BUILD_STATUS}" =~ WORKING|QUEUED ]]; do
    title_no_wait "Still waiting for cloud build to finish. Sleep for 5m"
    sleep 300
    BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_ADMIN} --format="value(id)" | head -n 1) --project ${TF_ADMIN} --format="value(status)")
done

echo -e "\n"
title_no_wait "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_ADMIN}. \n Exiting...."
  exit 1
fi

echo -e "\n"
title_no_wait "View the status of the Ops project Cloud Build in a previously opened tab or by clicking the following link: "
echo -e "\n"
title_no_wait "https://console.cloud.google.com/cloud-build/builds?project=${TF_VAR_ops_project_name}"
title_no_wait "Waiting for Cloud Build to finish..."

BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
while [[ "${BUILD_STATUS}" =~ WORKING|QUEUED ]]; do
    title_no_wait "Still waiting for cloud build to finish. Sleep for 1m"
    sleep 60
    BUILD_STATUS=$(gcloud builds describe $(gcloud builds list --project ${TF_VAR_ops_project_name} --format="value(id)" | head -n 1) --project ${TF_VAR_ops_project_name} --format="value(status)")
done

echo -e "\n"
title_no_wait "Build finished with status: $BUILD_STATUS"
echo -e "\n"

if [[ $BUILD_STATUS != "SUCCESS" ]]; then
  error_no_wait "Build unsuccessful. Check build logs at: \n https://console.cloud.google.com/cloud-build/builds?project=${TF_ADMIN}. \n Exiting...."
  exit 1
fi

title_and_wait "Run script to add the new clusters to the vars and kubeconfig file."
print_and_execute "${WORKDIR}/add-proj-repo/scripts/setup-gke-vars-kubeconfig-add-proj.sh ${WORKDIR}/asm"

title_and_wait "Change the KUBECONFIG variable to point to the new kubeconfig file."
print_and_execute "source ${WORKDIR}/asm/vars/vars.sh"
print_and_execute "export KUBECONFIG=${WORKDIR}/asm/gke/kubemesh"

title_and_wait "Verify there are now 9 cluster contexts"
print_and_execute "kubectl config view -ojson | jq -r '.clusters[].name'"
if [[ $(kubectl config view -ojson | jq -r '.clusters[].name' | wc -l) -ne 9 ]]; then
    error_no_wait "failed to find 9 cluster contexts"
    exit 1
fi

title_no_wait "Confirming Istio controlplane is deployed and Ready on the ops clusters..."
echo -e "\n"
# define ops clusters contexts
declare -a OPS_CLUSTER_CONTEXTS
export OPS_CLUSTER_CONTEXTS=(
    ${OPS_GKE_1}
    ${OPS_GKE_2}
    ${OPS_GKE_3}
)

# Define OPS cluster deployments - the full Istio controlplane
declare -a OPS_ISTIO_DEPLOYMENTS
export OPS_ISTIO_DEPLOYMENTS=(grafana 
                        istio-citadel 
                        istio-ingressgateway 
                        istio-egressgateway 
                        istio-galley 
                        istio-pilot 
                        istio-policy
                        istio-telemetry
                        istio-tracing
                        istio-sidecar-injector
                        istiocoredns
                        kiali
                        prometheus
                        )

title_no_wait "Waiting until all Deployments are Ready..."
for cluster in ${OPS_CLUSTER_CONTEXTS[@]}
    do
        title_no_wait "for Cluster ${cluster}"
        for deployment in ${OPS_ISTIO_DEPLOYMENTS[@]}
            do  
                is_deployment_ready ${cluster} istio-system ${deployment}
            done 
        echo -e "\n"
    done 
echo -e "\n"
title_no_wait "Istio Deployments are Ready in the ops clusters."

title_and_wait "Verify citadel, istio-sidecar-injector and coredns are deployed and all Pods are Running in all apps clusters."
title_no_wait "Getting Istio Pods in app-5 cluster in dev3 project..."
print_and_execute "kubectl --context ${DEV3_GKE_1} get pods -n istio-system"
echo -e "\n"
title_no_wait "Getting Istio Pods in app-6 cluster in dev3 project..."
print_and_execute "kubectl --context ${DEV3_GKE_2} get pods -n istio-system"
echo -e "\n"

title_no_wait "Confirming the required Istio controlplane components are deployed and Ready on the apps clusters..."
echo -e "\n"
# define apps clusters contexts
declare -a APP_CLUSTER_CONTEXTS
export APP_CLUSTER_CONTEXTS=(
    ${DEV3_GKE_1}
    ${DEV3_GKE_2}
)

# Define deployments running in shared clusters 
# only citadel, sidecar-injector and optionally coredns should be running
declare -a APP_ISTIO_DEPLOYMENTS
export APP_ISTIO_DEPLOYMENTS=( 
        istio-citadel 
        istio-sidecar-injector
        istiocoredns
        )

title_no_wait "Waiting until all Deployments are Ready..."
for cluster in ${APP_CLUSTER_CONTEXTS[@]}
    do
        title_no_wait "for Cluster ${cluster}"
        for deployment in ${APP_ISTIO_DEPLOYMENTS[@]}
            do  
                is_deployment_ready ${cluster} istio-system ${deployment}
            done 
        echo -e "\n"
    done 
echo -e "\n"
title_no_wait "Istio deployments are Ready in the apps clusters."

title_no_wait "Pilots running in the ops clusters use kubeconfig files to access and get services and endpoints from all apps clusters."
title_no_wait "The kubeconfig files for all four apps clusters are stored as secrets in the ops clusters."
title_and_wait "Ensure these secrets are created in both ops clusters."
echo -e "\n"
title_no_wait "Kubeconfig secrets in ops-1 cluster:"
print_and_execute "kubectl --context ${OPS_GKE_1} get secrets -l istio/multiCluster=true -n istio-system"
echo -e "\n"
title_no_wait "Kubeconfig secrets in ops-2 cluster:"
print_and_execute "kubectl --context ${OPS_GKE_2} get secrets -l istio/multiCluster=true -n istio-system"
echo -e "\n"
title_no_wait "Kubeconfig secrets in ops-3 cluster:"
print_and_execute "kubectl --context ${OPS_GKE_3} get secrets -l istio/multiCluster=true -n istio-system"
echo -e "\n"
export OPS1_NUM_OF_SECRETS=`kubectl --context ${OPS_GKE_1} get secrets -l istio/multiCluster=true -n istio-system | wc -l`
export OPS2_NUM_OF_SECRETS=`kubectl --context ${OPS_GKE_2} get secrets -l istio/multiCluster=true -n istio-system | wc -l`
export OPS3_NUM_OF_SECRETS=`kubectl --context ${OPS_GKE_3} get secrets -l istio/multiCluster=true -n istio-system | wc -l`
export OPS1_NUM_OF_SECRETS=$((${OPS2_NUM_OF_SECRETS}-1)) # num of lines include the header row. subtracting 1 to get num of secrets
export OPS2_NUM_OF_SECRETS=$((${OPS2_NUM_OF_SECRETS}-1)) # num of lines include the header row. subtracting 1 to get num of secrets
export OPS3_NUM_OF_SECRETS=$((${OPS3_NUM_OF_SECRETS}-1)) # num of lines include the header row. subtracting 1 to get num of secrets
if [ ${OPS1_NUM_OF_SECRETS} == 6 ]; then
    title_no_wait "You show ${OPS1_NUM_OF_SECRETS} secrets in ops-1 cluster. One for each app cluster. Looks good."
else
    error_no_wait "You show ${OPS1_NUM_OF_SECRETS} secrets in ops-1 cluster. You should see 6 secrets, one for each app cluster. Exiting script."
    exit 1
fi
if [ ${OPS2_NUM_OF_SECRETS} == 6 ]; then
    title_no_wait "You show ${OPS2_NUM_OF_SECRETS} secrets in ops-2 cluster. One for each app cluster. Looks good."
else
    title_no_wait "You show ${OPS2_NUM_OF_SECRETS} secrets in ops-2 cluster. You should see 6 secrets, one for each app cluster. Exiting script."
    exit 1
fi
if [ ${OPS3_NUM_OF_SECRETS} == 6 ]; then
    title_no_wait "You show ${OPS3_NUM_OF_SECRETS} secrets in ops-3 cluster. One for each app cluster. Looks good."
else
    title_no_wait "You show ${OPS3_NUM_OF_SECRETS} secrets in ops-3 cluster. You should see 6 secrets, one for each app cluster. Exiting script."
    exit 1
fi
echo -e "\n"

title_no_wait "Congratulations! You have successfully completed the Infrastructure Scaling lab."
echo -e "\n"
