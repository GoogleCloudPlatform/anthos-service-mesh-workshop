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
export LAB_NAME=mutual-tls

# Create a logs folder and file and send stdout and stderr to console and log file 
mkdir -p ${SCRIPT_DIR}/../logs
export LOG_FILE=${SCRIPT_DIR}/../logs/ft-${LAB_NAME}-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

source ${SCRIPT_DIR}/../scripts/functions.sh

# Lab: Mutual TLS

# Set speed
bold=$(tput bold)
normal=$(tput sgr0)

color='\e[1;32m' # green
nc='\e[0m'

echo -e "\n"
echo "${bold}*** Lab: Mutual TLS ***${normal}"
echo -e "\n"


title_and_wait "Check MeshPolicy in ops clusters. Note mTLS is PERMISSIVE allowing for both encrypted and non-mTLS traffic."
print_and_execute "kubectl --context ${OPS_GKE_1} get MeshPolicy -o yaml"
print_and_execute "kubectl --context ${OPS_GKE_2} get MeshPolicy -o yaml"
 
#Output (do not copy)
#
#  spec:
#    peers:
#    - mtls:
#        mode: PERMISSIVE

title_no_wait "Turn on mTLS. The Istio operator controller is running and we can change the "
title_no_wait "Istio configuration by editing or replacing the IstioControlPlane resource. "
title_no_wait "The controller will detect the change and respond by updating the Istio installation "
title_no_wait "accordingly. We will set mtls to enabled in the IstioControlPlane resource for both "
title_no_wait "the shared and replicated control plane. This will set the MeshPolicy to ISTIO_MUTUAL "
title_and_wait "and create a default Destination Rule."

print_and_execute "cd ${WORKDIR}/asm"
print_and_execute "sed -i '/global:/a\ \ \ \ \ \ mtls:\n\ \ \ \ \ \ \ \ enabled: true' ../k8s-repo/${OPS_GKE_1_CLUSTER}/istio-controlplane/istio-replicated-controlplane.yaml"
print_and_execute "sed -i '/global:/a\ \ \ \ \ \ mtls:\n\ \ \ \ \ \ \ \ enabled: true' ../k8s-repo/${OPS_GKE_2_CLUSTER}/istio-controlplane/istio-replicated-controlplane.yaml"
print_and_execute "sed -i '/global:/a\ \ \ \ \ \ mtls:\n\ \ \ \ \ \ \ \ enabled: true' ../k8s-repo/${DEV1_GKE_1_CLUSTER}/istio-controlplane/istio-shared-controlplane.yaml"
print_and_execute "sed -i '/global:/a\ \ \ \ \ \ mtls:\n\ \ \ \ \ \ \ \ enabled: true' ../k8s-repo/${DEV1_GKE_2_CLUSTER}/istio-controlplane/istio-shared-controlplane.yaml"
print_and_execute "sed -i '/global:/a\ \ \ \ \ \ mtls:\n\ \ \ \ \ \ \ \ enabled: true' ../k8s-repo/${DEV2_GKE_1_CLUSTER}/istio-controlplane/istio-shared-controlplane.yaml"
print_and_execute "sed -i '/global:/a\ \ \ \ \ \ mtls:\n\ \ \ \ \ \ \ \ enabled: true' ../k8s-repo/${DEV2_GKE_2_CLUSTER}/istio-controlplane/istio-shared-controlplane.yaml"
 
title_and_wait "Commit to k8s-repo."
print_and_execute "cd ${WORKDIR}/k8s-repo"
print_and_execute "git add . && git commit -am \"turn mTLS on\""
print_and_execute "git push"
 
title_and_wait "Wait for rollout to complete"
print_and_execute "${WORKDIR}/asm/scripts/stream_logs.sh $TF_VAR_ops_project_name"
 
title_no_wait "Verify mTLS"
title_and_wait "Check MeshPolicy once more in ops clusters. Note mTLS is no longer PERMISSIVE and will only allow for mTLS traffic."
print_and_execute "kubectl --context ${OPS_GKE_1} get MeshPolicy -o yaml"
print_and_execute "kubectl --context ${OPS_GKE_2} get MeshPolicy -o yaml"

# actually validate here
# Output (do not copy):
# 
# spec:
#     peers:
#     - mtls: {}


title_and_wait "Describe the DestinationRule created by the Istio operator controller."
print_and_execute "kubectl --context ${OPS_GKE_1} get DestinationRule default -n istio-system -o yaml"
print_and_execute "kubectl --context ${OPS_GKE_2} get DestinationRule default -n istio-system -o yaml"
 
#validate
#Output (do not copy):
#
#  apiVersion: networking.istio.io/v1alpha3
#  kind: DestinationRule
#  metadata:  
#    name: default
#    namespace: istio-system
#  spec:
#    host: '*.local'
#    trafficPolicy:
#      tls:
#        mode: ISTIO_MUTUAL

# show some logs that prove secure