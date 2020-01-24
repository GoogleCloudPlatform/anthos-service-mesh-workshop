#!/bin/bash

source ../${1}/env.sh


log "⭐️ Pushing ServiceEntry and selector-less Service to k8s_repo..."

# ServiceEntry on Ops clusters
sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g" -e "s/[[GCE_IP]]/${GCE_IP}/g" \
service-entry.tpl.yaml > ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/${SVC_NAME}-service-entry.yaml

sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g" -e "s/[[GCE_IP]]/${GCE_IP}/g" \
service-entry.tpl.yaml > ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/${SVC_NAME}-service-entry.yaml

echo "  - ${SVC_NAME}-service-entry.yaml" >> ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/kustomization.yaml
echo "  - ${SVC_NAME}-service-entry.yaml" >> ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/kustomization.yaml

# Service on all (Ops, dev) clusters
sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g"  \
service.tpl.yaml > ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app/services/${SVC_NAME}-service.yaml

sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g"  \
service.tpl.yaml > ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app/services/${SVC_NAME}-service.yaml

sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/services/${SVC_NAME}-service.yaml

sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/services/${SVC_NAME}-service.yaml

sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/services/${SVC_NAME}-service.yaml

sed -i '' -e "s/[[SVC_NAME]]/${SVC_NAME}/g" -e "s/[[SVC_PORT]]/${SVC_PORT}/g" -e "s/[[SVC_NAMESPACE]]/${SVC_NAMESPACE}/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/services/${SVC_NAME}-service.yaml

echo "  - ${SVC_NAME}-service.yaml" >> ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app/services/kustomization.yaml
echo "  - ${SVC_NAME}-service.yaml" >> ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app/services/kustomization.yaml
echo "  - ${SVC_NAME}-service.yaml" >> ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/services/kustomization.yaml
echo "  - ${SVC_NAME}-service.yaml" >> ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/services/kustomization.yaml
echo "  - ${SVC_NAME}-service.yaml" >> ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/services/kustomization.yaml
echo "  - ${SVC_NAME}-service.yaml" >> ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/services/kustomization.yaml

# Push to repo
cd $K8S_REPO
git add . && git commit -am "${SVC_NAME}- Adding VM ServiceEntry, Service"
git push
cd $VM_DIR

log "✅ Done."