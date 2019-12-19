#!/usr/bin/env bash

# TASK: Uninstall Istio from all clusters

source ./vars/vars.sh

kubectl --context ${OPS_GKE_1} delete -f ./k8s-repo/${OPS_GKE_1_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml
kubectl --context ${OPS_GKE_2} delete -f ./k8s-repo/${OPS_GKE_2_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml

rm ./k8s-repo/${OPS_GKE_1_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml
rm ./k8s-repo/${OPS_GKE_2_CLUSTER}/02_istio-replicated-controlplane-manifest.yaml

kubectl --context ${DEV1_GKE_1} delete -f ./k8s-repo/${DEV1_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
kubectl --context ${DEV1_GKE_2} delete -f ./k8s-repo/${DEV1_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
kubectl --context ${DEV2_GKE_1} delete -f ./k8s-repo/${DEV2_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml
kubectl --context ${DEV2_GKE_2} delete -f ./k8s-repo/${DEV2_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml

rm ./k8s-repo/${DEV1_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
rm ./k8s-repo/${DEV1_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev1-manifest.yaml
rm ./k8s-repo/${DEV2_GKE_1_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml
rm ./k8s-repo/${DEV2_GKE_2_CLUSTER}/02_istio-shared-controlplane-dev2-manifest.yaml 

cd ./k8s-repo
git add . && git commit -am "deleted istio"
git push google master
cd ..

