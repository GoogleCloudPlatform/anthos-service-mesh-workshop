#!/bin/bash

source ./env.sh
source ${1}/env.sh

# add network tags to VM  - needed for firewall rules
gcloud compute instances add-tags ${VM_NAME} --zone ${VM_ZONE} --tags=${VM_NAME}

# create 2 firewall rules (k8s to VM) for both Dev1 clusters

export K8S_POD_CIDR_1 =$(gcloud container clusters describe ${DEV1_GKE_1} --project ${PROJECT_ID} --zone ${DEV1_GKE_1_ZONE} --format=json | jq -r '.clusterIpv4Cidr')

gcloud compute firewall-rules create k8s-1-to-${VM_NAME} \
--PROJECT_ID=${PROJECT_ID} \
--source-ranges=$K8S_POD_CIDR \
--target-tags=${VM_NAME} \
--action=ALLOW \
--rules=tcp:${SVC_PORT}

# TODO - cluster 2