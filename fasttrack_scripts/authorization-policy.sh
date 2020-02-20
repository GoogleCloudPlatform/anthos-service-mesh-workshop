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
title_and_wait "Navigate into the authorization example directory."

print_and_execute "export AUTHZ_DIR=\"${WORKDIR}/asm/k8s_manifests/prod/app-authorization\""
print_and_execute "export K8S_REPO=\"${WORKDIR}/k8s-repo\""
print_and_execute "cd $AUTHZ_DIR"
 
title_no_wait "Inspect the contents of currency-deny-all.yaml. This policy uses Deployment label selectors "
title_no_wait "to restrict access to the currencyservice. Notice how there is no spec field - this means this"
title_and_wait "policy will deny all access to the selected service."
print_and_execute "cat currency-deny-all.yaml && echo ''"
 
# apiVersion: "security.istio.io/v1beta1"
# kind: "AuthorizationPolicy"
# metadata:
#   name: "currency-policy"
#   namespace: currency
# spec:
#   selector:
#     matchLabels:
#       app: currencyservice

title_and_wait "Copy the currency policy into k8s-repo, for the ops clusters both regions."
print_and_execute "mkdir -p ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-authorization/"
print_and_execute "sed -i '/  - app-ingress\\//a\\ \\ - app-authorization\\/' ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/kustomization.yaml"
print_and_execute "cp currency-deny-all.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cd ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-authorization/; kustomize create --autodetect"
print_and_execute "cd $AUTHZ_DIR "
print_and_execute " "
print_and_execute "mkdir -p ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-authorization/"
print_and_execute "sed -i '/  - app-ingress\\//a\\ \\ - app-authorization\\/' ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/kustomization.yaml"
print_and_execute "cp currency-deny-all.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cd ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-authorization/; kustomize create --autodetect"
 
title_and_wait "Push changes."
print_and_execute "cd $K8S_REPO "
print_and_execute "git add . && git commit -am \"AuthorizationPolicy - currency: deny all\""
print_and_execute "git push"
sleep 15
print_and_execute "cd $AUTHZ_DIR"

 
title_no_wait "Try to reach the hipstershop frontend in a browser:"
echo "https://frontend.endpoints.${TF_VAR_ops_project_name}.cloud.goog" 
title_no_wait "You should see an Authorization error from currencyservice:"
echo "Uh oh!  Something has failed... (500 Internal Server error)"
title_and_wait ""
 

title_no_wait "Let's investigate how the currency service is enforcing this AuthorizationPolicy. "
title_no_wait "First, enable trace-level logs on the Envoy proxy for one of the currency pods, since "
title_and_wait "blocked authorization calls aren't logged by default."
print_and_execute "CURRENCY_POD=$(kubectl --context ${DEV1_GKE_2} get pod -n currency | grep currency| awk '{ print $1 }')"
print_and_execute "kubectl --context ${DEV1_GKE_2} exec $CURRENCY_POD -n currency -c istio-proxy \"curl -X POST \"http://localhost:15000/logging?level=trace\"; exit "
 
title_no_wait "Get the RBAC (authorization) logs from the currency service's sidecar proxy."
title_no_wait "You should see an \"enforced denied\" message, indicating that the currencyservice "
title_and_wait "is set to block all inbound requests."
print_and_execute "kubectl --context ${DEV1_GKE_2} logs -n currency $CURRENCY_POD -c istio-proxy | grep -m 3 rbac"
 
# Output (do not copy)
# 
# [Envoy (Epoch 0)] [2020-01-30 00:45:50.815][22][debug][rbac] [external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:67] checking request: remoteAddress: 10.16.5.15:37310, localAddress: 10.16.3.8:7000, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/frontend/sa/frontend, subjectPeerCertificate: , headers: ':method', 'POST'
# [Envoy (Epoch 0)] [2020-01-30 00:45:50.815][22][debug][rbac] [external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:118] enforced denied
# [Envoy (Epoch 0)] [2020-01-30 00:45:50.815][22][debug][http] [external/envoy/source/common/http/conn_manager_impl.cc:1354] [C115][S17310331589050212978] Sending local reply with details rbac_access_denied

title_no_wait "Now, let's allow the frontend -- but not the other backend services -- to access currencyservice."
title_and_wait "Open currency-allow-frontend.yaml and inspect its contents. Note that we've added the following rule:"
print_and_execute "cat currency-allow-frontend.yaml && echo ''"

title_no_wait "Here, we are whitelisting a specific source.principal (client) to access currency service."
title_no_wait "This source.principal is defined by is Kubernetes Service Account. In this case, the service "
title_no_wait "account we're whitelisting is the frontend service account in the frontend namespace."
title_no_wait " "
title_no_wait "Note: when using Kubernetes Service Accounts in Istio AuthorizationPolicies, you must first "
title_no_wait "enable cluster-wide mutual TLS, as we did in Module 1."
title_and_wait "This is to ensure that service account credentials are mounted into requests."

title_and_wait "Copy over the updated currency policy"
print_and_execute "cp $AUTHZ_DIR/currency-allow-frontend.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cp $AUTHZ_DIR/currency-allow-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-authorization/currency-policy.yaml"
 
title_and_wait "Push changes."
print_and_execute "cd $K8S_REPO"
print_and_execute "git add . && git commit -am \"AuthorizationPolicy - currency: allow frontend\""
print_and_execute "git push"
print_and_execute "cd $AUTHZ_DIR"
 
title_and_wait "Wait for Cloud Build to complete."
title_no_wait "Open the Hipstershop frontend again. This time you should see no errors in the homepage - this is "
title_no_wait "because we've explicitly allowed the frontend to access the current service.
title_no_wait "Now, try to execute a checkout, by adding items to your cart and clicking \"place order.\""
title_no_wait "This time, you should see a price-conversion error from currency service - this is because we "
title_and_wait "have only whitelisted the frontend, so the checkoutservice is still unable to access currencyservice.


title_no_wait "Finally, let's allow the checkout service access to currency, by adding another rule to our "
title_no_wait "currencyservice AuthorizationPolicy. Note that we are only opening up currency access to the two "
title_and_wait "services that need to access it - frontend and checkout. The other backends will still be blocked."

title_no_wait "Open currency-allow-frontend-checkout.yaml and inspect its contents. Notice that the list of rules "
title_no_wait "functions as a logical OR - currency will accept only requests from workloads with either of these "
title_and_wait "two service accounts."
print_and_execute "cat currency-allow-frontend-checkout.yaml && echo ''"
 
title_no_wait "Copy the final authorization policy to k8s-repo."
print_and_execute "cp $AUTHZ_DIR/currency-allow-frontend-checkout.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-authorization/currency-policy.yaml"
print_and_execute "cp $AUTHZ_DIR/currency-allow-frontend-checkout.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-authorization/currency-policy.yaml"
 
title_and_wait "Push changes"
print_and_execute "cd $K8S_REPO "
print_and_execute "git add . && git commit -am \"AuthorizationPolicy - currency: allow frontend and checkout\""
print_and_execute "git push"
 
title_and_wait "Wait for Cloud Build to complete."
title_and_wait "Try to execute a checkout - it should work successfully."

echo "This section walked through how to use Istio Authorization Policies to enforce granular access control at the per-service level. In production, you might create one AuthorizationPolicy per service, and (for instance) use an allow-all policy to let all workloads in the same namespace access each other."

echo "done with auth"