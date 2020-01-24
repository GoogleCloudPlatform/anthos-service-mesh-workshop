#!/bin/bash
# Send ops cluster (Istio ctrl plane) info to the VM

source ../${1}/env.sh

log "📦 Generating cluster.env for the VM..."
ISTIO_SERVICE_CIDR=$(gcloud container clusters describe ${OPS_GKE_1_CLUSTER} \
                       --zone ${OPS_GKE_1_LOCATION} --project ${TF_VAR_ops_project_name} \
                       --format "value(servicesIpv4Cidr)")

log "istio CIDR is: ${ISTIO_SERVICE_CIDR}"
echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\nISTIO_INBOUND_PORTS=${SVC_PORT}" | tee cluster.env

# get service account keys for the namespace this service will live in on the cluster
# (eg. payment, product-catalog) - this is the VM sidecar's "pod identity" that will allow mTLS to work.
kubectl --context ${OPS_GKE_1} -n ${SVC_NAMESPACE} get secret istio.default \
  -o jsonpath='{.data.root-cert\.pem}' | base64 --decode | tee root-cert.pem
kubectl --context ${OPS_GKE_1} -n ${SVC_NAMESPACE} get secret istio.default \
  -o jsonpath='{.data.key\.pem}' | base64 --decode | tee key.pem
kubectl --context ${OPS_GKE_1} -n ${SVC_NAMESPACE} get secret istio.default \
  -o jsonpath='{.data.cert-chain\.pem}' | base64 --decode | tee cert-chain.pem

log "📬 Sending cluster.env and certs to VM..."
gcloud compute --project ${TF_VAR_dev1_project_name} scp --zone ${VM_ZONE} \
  run-on-vm.sh cluster.env *.pem ${VM_NAME}:
log "✅ Done."