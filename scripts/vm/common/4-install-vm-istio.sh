#!/bin/bash

source ../${1}/env.sh

log "🛸 Installing Istio on the VM..."

GWIP=$(kubectl --context ${OPS_GKE_1} get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ops1 Ingress Gateway IP is ${GWIP}"

gcloud compute ssh --project ${TF_VAR_dev1_project_name} --zone $ZONE $SVC_NAME -- "ISTIO_VERSION='1.4.2' GWIP=${GWIP} ./run-on-vm.sh"

log "✅ Done."