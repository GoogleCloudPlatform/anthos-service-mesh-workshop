#!/bin/bash
# 💳 PAYMENTSERVICE VARS

VM_NAME_PREFIX="gce-vm-external"
VM_NAME=`gcloud compute instances list --filter="name~'${VM_NAME_PREFIX}*'" --format=json | \
 jq -r '.[]|select(.name | startswith("${VM_NAME_PREFIX")) | .name'`

VM_ZONE="us-west1-a"
SVC_NAME="paymentservice"
SVC_PORT="50051"
SVC_NAMESPACE="payment"
DOCKER_IMAGE="gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3"
