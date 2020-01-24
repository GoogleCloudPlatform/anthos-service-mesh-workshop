#!/bin/bash
# 💳 PAYMENTSERVICE VARS

# set -euo pipefail
log() { echo "$1" >&2; }

log "🌥Getting info..."
VM_NAME_PREFIX="gce-vm-external"
VM_NAME=`gcloud compute instances list --project ${TF_VAR_dev1_project_name} --filter="name~'${VM_NAME_PREFIX}*'" --format=json | jq '.[0] | .name'`
VM_NAME=`echo ${VM_NAME} | tr -d '"'`

LONG_ZONE=`gcloud compute instances list --project ${TF_VAR_dev1_project_name} --filter="name~'${VM_NAME_PREFIX}*'" --format=json | jq '.[0] | .zone'`
VM_ZONE=`basename $LONG_ZONE | tr -d '"'`

FILE_NAME="app-payment-service"
SVC_NAME="paymentservice"
SVC_PORT="50051"
SVC_NAMESPACE="payment"
DOCKER_IMAGE="gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3"
