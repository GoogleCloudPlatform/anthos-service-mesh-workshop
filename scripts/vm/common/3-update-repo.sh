#!/bin/bash

source ../${1}/env.sh

# log "🗑 Deleting existing Deployment, Service for ${SVC_NAME}..."
# rm ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/deployments/${FILE_NAME}.yaml
# rm ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/deployments/${FILE_NAME}.yaml
# rm ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/deployments/${FILE_NAME}.yaml
# rm ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/deployments/${FILE_NAME}.yaml

# # delete svc
# rm ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app/services/${FILE_NAME}-svc.yaml
# rm ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app/services/${FILE_NAME}-svc.yaml
# rm ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/services/${FILE_NAME}-svc.yaml
# rm ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/services/${FILE_NAME}-svc.yaml
# rm ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/services/${FILE_NAME}-svc.yaml
# rm ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/services/${FILE_NAME}-svc.yaml


# log "⭐️ Generating ServiceEntry.."
# sed -i -e "s/{SVC_NAME}/${SVC_NAME}/g" -e "s/{SVC_PORT}/${SVC_PORT}/g" -e "s/{SVC_NAMESPACE}/${SVC_NAMESPACE}/g" -e "s/{GCE_IP}/${GCE_IP}/g" \
# service-entry.tpl.yaml > ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/${FILE_NAME}-service-entry.yaml

# sed -i -e "s/{SVC_NAME}/${SVC_NAME}/g" -e "s/{SVC_PORT}/${SVC_PORT}/g" -e "s/{SVC_NAMESPACE}/${SVC_NAMESPACE}/g" -e "s/{GCE_IP}/${GCE_IP}/g" \
# service-entry.tpl.yaml > ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/${FILE_NAME}-service-entry.yaml

# echo "  - ${FILE_NAME}-service-entry.yaml" >> ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/istio-networking/kustomization.yaml
# echo "  - ${FILE_NAME}-service-entry.yaml" >> ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/istio-networking/kustomization.yaml


log "☸️ Generating selector-less Kubernetes Service.."
sed -e "s/{SVC_NAME}/$SVC_NAME/g" -e "s/{SVC_PORT}/$SVC_PORT/g" -e "s/{SVC_NAMESPACE}/$SVC_NAMESPACE/g"  \
service.tpl.yaml > ${K8S_REPO}/${OPS_GKE_1_CLUSTER}/app/services/${FILE_NAME}-svc.yaml

sed -e "s/{SVC_NAME}/$SVC_NAME/g" -e "s/{SVC_PORT}/$SVC_PORT/g" -e "s/{SVC_NAMESPACE}/$SVC_NAMESPACE/g"  \
service.tpl.yaml > ${K8S_REPO}/${OPS_GKE_2_CLUSTER}/app/services/${FILE_NAME}-svc.yaml

sed -e "s/{SVC_NAME}/$SVC_NAME/g" -e "s/{SVC_PORT}/$SVC_PORT/g" -e "s/{SVC_NAMESPACE}/$SVC_NAMESPACE/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV1_GKE_1_CLUSTER}/app/services/${FILE_NAME}-svc.yaml

sed -e "s/{SVC_NAME}/$SVC_NAME/g" -e "s/{SVC_PORT}/$SVC_PORT/g" -e "s/{SVC_NAMESPACE}/$SVC_NAMESPACE/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV1_GKE_2_CLUSTER}/app/services/${FILE_NAME}-svc.yaml

sed -e "s/{SVC_NAME}/$SVC_NAME/g" -e "s/{SVC_PORT}/$SVC_PORT/g" -e "s/{SVC_NAMESPACE}/$SVC_NAMESPACE/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV2_GKE_1_CLUSTER}/app/services/${FILE_NAME}-svc.yaml

sed -e "s/{SVC_NAME}/$SVC_NAME/g" -e "s/{SVC_PORT}/$SVC_PORT/g" -e "s/{SVC_NAMESPACE}/$SVC_NAMESPACE/g"  \
service.tpl.yaml > ${K8S_REPO}/${DEV2_GKE_2_CLUSTER}/app/services/${FILE_NAME}-svc.yaml


# Push to repo
# log "⬆️ Pushing to repo..."
# cd $K8S_REPO
# git add . && git commit -am "${SVC_NAME}- Adding VM ServiceEntry, Service"
# git push
# cd $VM_DIR

log "✅ Done."