#!/bin/bash

source ../${1}/env.sh

# add network tags to VM  - needed for firewall rules
log "🏷 Adding network tag to VM..."
gcloud compute instances add-tags ${VM_NAME} \
 --project ${TF_VAR_dev1_project_name} --zone ${VM_ZONE} --tags=${VM_NAME}

# cluster 1 --> VM firewall rule
log "🔥 Adding Cluster1 firewall rule..."
export DEV1_GKE_1_POD_CIDR=$(gcloud container clusters describe \
 ${DEV1_GKE_1_CLUSTER} --project ${TF_VAR_dev1_project_name} \
 --zone ${DEV1_GKE_1_LOCATION} --format=json | jq -r '.clusterIpv4Cidr')

gcloud compute firewall-rules create k8s-1-to-${VM_NAME} \
--project=${TF_VAR_host_project_name} \
--network="shared-vpc" \
--source-ranges=${DEV1_GKE_1_POD_CIDR} \
--target-tags=${VM_NAME} \
--action=ALLOW \
--rules=tcp:${SVC_PORT}

# cluster 2 --> VM firewall rule
log "🔥 Adding Cluster2 firewall rule..."
export DEV1_GKE_2_POD_CIDR=$(gcloud container clusters describe \
 ${DEV1_GKE_2_CLUSTER} --project ${TF_VAR_dev1_project_name} \
 --zone ${DEV1_GKE_2_LOCATION} --format=json | jq -r '.clusterIpv4Cidr')

gcloud compute firewall-rules create k8s-2-to-${VM_NAME} \
--project=${TF_VAR_host_project_name} \
--network="shared-vpc" \
--source-ranges=${DEV1_GKE_2_POD_CIDR} \
--target-tags=${VM_NAME} \
--action=ALLOW \
--rules=tcp:${SVC_PORT}

log "✅ Done."
