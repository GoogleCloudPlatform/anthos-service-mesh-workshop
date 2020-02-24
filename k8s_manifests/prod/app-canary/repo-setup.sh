#!/bin/bash
log() { echo "$1" >&2; }

# Export a SCRIPT_DIR var and make all links relative to SCRIPT_DIR
export SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")
source ${SCRIPT_DIR}/../scripts/functions.sh

# DEV1
log "📑 Generating Dev1 Manifests ..."

CANARY_DIR="${WORKDIR}/asm/k8s_manifests/prod/app-canary/"
K8S_REPO="${WORKDIR}/k8s-repo"

# Frontend + Respy - Dev1 GKE 1
cp $CANARY_DIR/baseline/app-respy.yaml ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/
cp $CANARY_DIR/baseline/app-frontend* ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/
cd ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/
kustomize edit add resource app-frontend-v2.yaml
kustomize edit add resource app-respy.yaml

# Frontend v2 - Dev2 GKE 2
cp $CANARY_DIR/baseline/app-frontend* ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/deployments/
cd ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/deployments/
kustomize edit add resource app-frontend-v2.yaml

# Frontend baseline VirtualService, DestinationRule - send all traffic to the existing v1
cp $CANARY_DIR/baseline/dr-frontend.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/
cp $CANARY_DIR/baseline/vs-frontend.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/
cd ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/
kustomize edit add resource dr-frontend.yaml
kustomize edit add resource vs-frontend.yaml

#DEV2
log "📑 Generating Dev2 Manifests ..."

# Frontend + Respy - DEV2 GKE 1
cp $CANARY_DIR/baseline/app-respy.yaml ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/
cp $CANARY_DIR/baseline/app-frontend* ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/
cd ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/
kustomize edit add resource app-frontend-v2.yaml
kustomize edit add resource app-respy.yaml

# Frontend v2 - Dev2 GKE 2
cp $CANARY_DIR/baseline/app-frontend* ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/deployments/
cd ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/deployments/
kustomize edit add resource app-frontend-v2.yaml

# Frontend baseline VirtualService, DestinationRule - send all traffic to the existing v1
cp $CANARY_DIR/baseline/dr-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cp $CANARY_DIR/baseline/vs-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cd ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
kustomize edit add resource dr-frontend.yaml
kustomize edit add resource vs-frontend.yaml

log "✅ Generated baseline Canary manifests."
cd ${CANARY_DIR}