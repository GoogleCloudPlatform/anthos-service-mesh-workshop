#!/bin/bash
# 💳 PAYMENTSERVICE VARS

set -euo pipefail
log() { echo "$1" >&2; }

VM_NAME_PREFIX="gce-vm-external"
VM_NAME=`gcloud compute instances list --project ${TF_VAR_dev1_project_name} --filter="name~'${VM_NAME_PREFIX}*'" --format=json | jq '.[0] | .name'`

LONG_ZONE=`gcloud compute instances list --project ${TF_VAR_dev1_project_name} --filter="name~'${VM_NAME_PREFIX}*'" --format=json | jq '.[0] | .zone'`
VM_ZONE=`basename $LONG_ZONE | tr -d '"'`
echo $VM_ZONE

SVC_NAME="paymentservice"
SVC_PORT="50051"
SVC_NAMESPACE="payment"
DOCKER_IMAGE="gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3"
