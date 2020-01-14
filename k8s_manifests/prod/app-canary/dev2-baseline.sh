#!/bin/bash

CANARY_DIR="/home/`whoami`/anthos-service-mesh-lab/asm/k8s_manifests/prod/app-canary"
K8S_REPO="/home/`whoami`/anthos-service-mesh-lab/k8s-repo"

cd $CANARY_DIR

cp baseline/app-respy.yaml ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/
echo "  - app-frontend-v2.yaml" >> ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/kustomization.yaml
echo "  - app-frontend-v2.yaml" >> ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/deployments/kustomization.yaml
echo "  - app-respy.yaml" >> ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/kustomization.yaml

mkdir -p ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
sed -i '/  - app-ingress\//a\ \ - app-canary\/' ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/kustomization.yaml
cp baseline/kustomization.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cp baseline/dr-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cp baseline/vs-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/

mkdir -p ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
sed -i '/  - app-ingress\//a\ \ - app-canary\/' ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/kustomization.yaml
cp baseline/kustomization.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cp baseline/dr-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/
cp baseline/vs-frontend.yaml ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app-canary/

cd $K8S_REPO
git add . && git commit -am "frontend canary setup for DEV2 region"
git push
cd $CANARY_DIR
