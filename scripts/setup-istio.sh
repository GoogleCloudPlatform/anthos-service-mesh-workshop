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

# Import functions
. ./scripts/functions.sh 

# TASK 2: Setup Istio

# Font colors
export CYAN='\033[1;36m' 
export GREEN='\033[1;32m'
export NC='\033[0m' # No Color

# Create a log file and send stdout and stderr to console and log file 
mkdir -p logs
export LOG_FILE=setup-istio-$(date +%s).log
touch ./logs/${LOG_FILE}
exec 2>&1
exec &> >(tee -i ./logs/${LOG_FILE})

export VARS_FILE=./vars/vars.sh
source ./vars/vars.sh

# Define your OPS and DEV clusters here
# OPS clusters will get the replicated controlplane configs
# DEV clusters will get the shared control plane configs
# OPS cluster number and DEV project number should match i.e. OPS_GKE_1 cluster will 
# service as the controlplane for all DEV1  GKE clusters and so on
# In the current setup, you have two OPS clusters and two associated DEV clusters for each OPS cluster as shown below

declare -a OPS_CLUSTER_CONTEXTS
export OPS_CLUSTER_CONTEXTS=(
    ${OPS_GKE_1}
    ${OPS_GKE_2}
)

declare -a OPS_CLUSTER_NAMES
export OPS_CLUSTER_NAMES=(
    ${OPS_GKE_1_CLUSTER}
    ${OPS_GKE_2_CLUSTER}
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

# Define OPS cluster control plane services, namely pilot, telemetry and policy
declare -a ISTIO_CONTROLPLANE_SERVICES
export ISTIO_CONTROLPLANE_SERVICES=(
    istio-pilot
    istio-policy
    istio-telemetry
)


# Each OPS cluster must have an associated DEV cluster array
declare -a OPS_1_DEV_CLUSTER_CONTEXTS
export OPS_1_DEV_CLUSTER_CONTEXTS=(
    ${DEV1_GKE_1}
    ${DEV1_GKE_2}
)

declare -a OPS_1_DEV_CLUSTER_NAMES
export OPS_1_DEV_CLUSTER_NAMES=(
    ${DEV1_GKE_1_CLUSTER}
    ${DEV1_GKE_2_CLUSTER}
)

declare -a OPS_2_DEV_CLUSTER_CONTEXTS
export OPS_2_DEV_CLUSTER_CONTEXTS=(
    ${DEV2_GKE_1}
    ${DEV2_GKE_2}
)

declare -a OPS_2_DEV_CLUSTER_NAMES
export OPS_2_DEV_CLUSTER_NAMES=(
    ${DEV2_GKE_1_CLUSTER}
    ${DEV2_GKE_2_CLUSTER}
)

# Define deployments running in shared clusters 
# only citadel, sidecar-injector and optionally coredns should be running
declare -a DEV_ISTIO_DEPLOYMENTS
export DEV_ISTIO_DEPLOYMENTS=( 
        istio-citadel 
        istio-sidecar-injector
        istiocoredns
        )

# echo -e "\n${CYAN}Getting Istio...${NC}"
# gsutil -m cp -r gs://${TF_ADMIN}/ops/istio-${ISTIO_VERSION} .

echo -e "\n${CYAN}Creating helm template using Istio replicated control plane values...${NC}"
helm template ./istio-${ISTIO_VERSION}/install/kubernetes/helm/istio \
--name istio --namespace istio-system --values ./istio/01_istio-replicated-controlplane-values.yaml \
> ./tmp/02_istio-replicated-controlplane-manifest.yaml


echo -e "\n${CYAN}Copying Istio replicated control plane manifests to ops cluster k8s-repo folders...${NC}"
for ops_cluster in ${OPS_CLUSTER_NAMES[@]}
do
    cp ./tmp/02_istio-replicated-controlplane-manifest.yaml ./k8s-repo/${ops_cluster}/.
done

echo -e "\n${CYAN}Committing and pushing to k8s-repo to deploy Istio on ops clusters...${NC}"
cd ./k8s-repo
git add . && git commit -am "deploy istio controlplane to ops clusters"
git push google master
cd ..

echo -e "\n${CYAN}Waiting until all deployments are ready...${NC}"
for cluster in ${OPS_CLUSTER_CONTEXTS[@]}
    do
        for deployment in ${OPS_ISTIO_DEPLOYMENTS[@]}
            do 
                is_istio_deployment_ready ${cluster} ${deployment}
            done 
    done 
echo -e "\n${CYAN}All Istio deployments are ready in ops clusters.${NC}"

echo -e "\n${CYAN}Exposing pilot, policy and telemetry using ILB...${NC}"
for cluster in ${OPS_CLUSTER_CONTEXTS[@]}
    do
        for service in ${ISTIO_CONTROLPLANE_SERVICES[@]}
            do
                expose_istio_svc_via_ilb ${cluster} ${service}
            done
    done
echo -e "\n${CYAN}Pilot, policy and telemetry patched for ILB.${NC}"

echo -e "\n${CYAN}Waiting for ILB IP address assignments...${NC}"
for cluster in ${OPS_CLUSTER_CONTEXTS[@]}
    do
        for service in ${ISTIO_CONTROLPLANE_SERVICES[@]}
            do
                get_istio_svc_ingress_ip ${cluster} ${service}
            done
    done
echo -e "\n${CYAN}ILB IP addresses assigned.${NC}"

echo -e "\n${CYAN}Exporting ILB IP as variables...${NC}"
for idx in ${!OPS_CLUSTER_CONTEXTS[@]}
    do 
        ops_idx=$((idx + 1))
        echo -e "export OPS_GKE_${ops_idx}_PILOT_ILB_IP=$(kubectl --context ${OPS_CLUSTER_CONTEXTS[idx]} -n istio-system get svc istio-pilot -o json | jq -r '.status.loadBalancer.ingress[].ip')" | tee -a ${VARS_FILE}
        echo -e "export OPS_GKE_${ops_idx}_POLICY_ILB_IP=$(kubectl --context ${OPS_CLUSTER_CONTEXTS[idx]} -n istio-system get svc istio-policy -o json | jq -r '.status.loadBalancer.ingress[].ip')" | tee -a ${VARS_FILE}
        echo -e "export OPS_GKE_${ops_idx}_TELEMETRY_ILB_IP=$(kubectl --context ${OPS_CLUSTER_CONTEXTS[idx]} -n istio-system get svc istio-telemetry -o json | jq -r '.status.loadBalancer.ingress[].ip')" | tee -a ${VARS_FILE}
    done

source ./vars/vars.sh

for idx in ${!OPS_CLUSTER_CONTEXTS[@]}
    do 
        ops_idx=$((idx + 1))
        echo -e "\n${CYAN}Creating helm template using Istio shared control plane values for dev${ops_idx} clusters...${NC}"
        
        PILOT_ILB_IP=OPS_GKE_${ops_idx}_PILOT_ILB_IP
        POLICY_ILB_IP=OPS_GKE_${ops_idx}_POLICY_ILB_IP
        TELEMETRY_ILB_IP=OPS_GKE_${ops_idx}_TELEMETRY_ILB_IP
        
        helm template ./istio-${ISTIO_VERSION}/install/kubernetes/helm/istio \
        --name istio-remote --namespace istio-system \
        --values ./istio/01_istio-shared-controlplane-values.yaml \
        --set global.remotePilotAddress=${!PILOT_ILB_IP} \
        --set global.remotePolicyAddress=${!POLICY_ILB_IP} \
        --set global.remoteTelemetryAddress=${!TELEMETRY_ILB_IP} > ./tmp/02_istio-shared-controlplane-dev${ops_idx}-manifest.yaml

        TMP_VAR="OPS_${ops_idx}_DEV_CLUSTER_NAMES"
        declare -a DEV_CLUSTER_NAMES="${TMP_VAR}[@]"

        for dev_cluster in ${!DEV_CLUSTER_NAMES}
            do
                echo -e "\n${CYAN}Copying Istio shared control plane manifests to the ${dev_cluster} cluster k8s-repo folders...${NC}"
                cp ./tmp/02_istio-shared-controlplane-dev${ops_idx}-manifest.yaml ./k8s-repo/${dev_cluster}/.
            done
    done


echo -e "\n${CYAN}Committing and pushing to k8s-repo to deploy Istio on dev clusters...${NC}"
cd ./k8s-repo
git add . && git commit -am "deploy istio to dev clusters"
git push google master
cd ..


echo -e "\n${CYAN}Waiting until all dev deployments are ready...${NC}"
for idx in ${!OPS_CLUSTER_CONTEXTS[@]}
    do
        ops_idx=$((idx + 1))
        TMP_VAR="OPS_${ops_idx}_DEV_CLUSTER_CONTEXTS"
        declare -a DEV_CLUSTER_CONTEXTS="${TMP_VAR}[@]"

        for dev_cluster in ${!DEV_CLUSTER_CONTEXTS}
            do
            for deployment in ${DEV_ISTIO_DEPLOYMENTS[@]}
                do 
                    is_istio_deployment_ready ${dev_cluster} ${deployment}
                done 
            done
    done 
echo -e "\n${CYAN}All Istio deployments are ready in dev clusters.${NC}"
