#!/bin/bash

source ../${1}/env.sh


log "⭐️ Registering VM with the Istio control plane..."

export GCE_IP=$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances describe ${VM_NAME} --project ${TF_VAR_dev1_project_name} --zone=${VM_ZONE})
echo "GCE IP is: ${GCE_IP}"

"kubectl -n ${SVC_NAMESPACE} apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: ${SVC_NAME}
spec:
  hosts:
  - ${SVC_NAME}.${SVC_NAMESPACE}.svc.cluster.local
  ports:
  - number: ${SVC_PORT}
    name: grpc
    protocol: GRPC
  resolution: STATIC
  endpoints:
  - address: ${GCE_IP}
    ports:
      grpc: 3550
    labels:
      app: productcatalogservice
EOF"

istioctl register -n ${SVC_NAMESPACE} ${SVC_NAME} ${GCE_IP} grpc:${SVC_PORT}
log "✅ Done."