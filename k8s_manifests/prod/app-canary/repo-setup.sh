#!/bin/bash
log() { echo "$1" >&2; }

# DEV1
log "📑 Generating Dev1 Manifests ..."

# Frontend v2
cp baseline/app-frontend* ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/
cp baseline/app-frontend* ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/deployments/
echo "  - app-frontend-v2.yaml" >> ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/kustomization.yaml
echo "  - app-frontend-v2.yaml" >> ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/deployments/kustomization.yaml

# Respy
cp baseline/app-respy.yaml ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/
echo "  - app-respy.yaml" >> ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/kustomization.yaml

# VS and DR
mkdir -p ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/
sed -i '/  - app-ingress\//a\ \ - app-canary\/' ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/kustomization.yaml
cp baseline/kustomization.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/
cp baseline/dr-frontend.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/
cp baseline/vs-frontend.yaml ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/


#DEV2
log "📑 Generating Dev2 Manifests ..."

# Frontend V2
cp baseline/app-frontend* ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/
cp baseline/app-frontend* ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/deployments/
echo "  - app-frontend-v2.yaml" >> ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/kustomization.yaml
echo "  - app-frontend-v2.yaml" >> ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/deployments/kustomization.yaml

# Respy
cp baseline/app-respy.yaml ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/
echo "  - app-respy.yaml" >> ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/kustomization.yaml

# VS and DR
mkdir -p ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app-canary/
sed -i '/  - app-ingress\//a\ \ - app-canary\/' ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/kustomization.yaml
cp baseline/kustomization.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cp baseline/dr-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cp baseline/vs-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/


log "✅ Manifests copied."