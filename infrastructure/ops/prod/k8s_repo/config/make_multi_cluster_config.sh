#!/bin/bash

set -e

export KUBECTL_VERSION=1.16.1
export KUSTOMIZE_VERSION=3.5.3

# Install kubectl
wget -q https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/

# Install kustomize
wget -qO- https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | \
  tar zxvf - kustomize && \
  chmod +x kustomize && \
  mv kustomize /usr/local/bin

# Save cluster credentials to $KUBECONFIG
gcloud container clusters get-credentials "${OPS_GKE_1_CLUSTER}" --region "${OPS_GKE_1_LOCATION}" --project "${OPS_PROJECT_ID}"
gcloud container clusters get-credentials "${OPS_GKE_2_CLUSTER}" --region "${OPS_GKE_2_LOCATION}" --project "${OPS_PROJECT_ID}"
gcloud container clusters get-credentials "${DEV1_GKE_1_CLUSTER}" --zone "${DEV1_GKE_1_LOCATION}" --project "${DEV1_PROJECT_ID}"
gcloud container clusters get-credentials "${DEV1_GKE_2_CLUSTER}" --zone "${DEV1_GKE_2_LOCATION}" --project "${DEV1_PROJECT_ID}"
gcloud container clusters get-credentials "${DEV2_GKE_1_CLUSTER}" --zone "${DEV2_GKE_1_LOCATION}" --project "${DEV2_PROJECT_ID}"
gcloud container clusters get-credentials "${DEV2_GKE_2_CLUSTER}" --zone "${DEV2_GKE_2_LOCATION}" --project "${DEV2_PROJECT_ID}"

export OPS_GKE_1=gke_${OPS_PROJECT_ID}_${OPS_GKE_1_LOCATION}_${OPS_GKE_1_CLUSTER}
export OPS_GKE_2=gke_${OPS_PROJECT_ID}_${OPS_GKE_2_LOCATION}_${OPS_GKE_2_CLUSTER}
export DEV1_GKE_1=gke_${DEV1_PROJECT_ID}_${DEV1_GKE_1_LOCATION}_${DEV1_GKE_1_CLUSTER}
export DEV1_GKE_2=gke_${DEV1_PROJECT_ID}_${DEV1_GKE_2_LOCATION}_${DEV1_GKE_2_CLUSTER}
export DEV2_GKE_1=gke_${DEV2_PROJECT_ID}_${DEV2_GKE_1_LOCATION}_${DEV2_GKE_1_CLUSTER}
export DEV2_GKE_2=gke_${DEV2_PROJECT_ID}_${DEV2_GKE_2_LOCATION}_${DEV2_GKE_2_CLUSTER}


# Build dev cluster kubeconfig secrets for the ops clusters
# This is for service discovery in the shared clusters.
function build_cluster_config() {
  CLUSTER_NAME=$1
  CLUSTER_CA=$2
  CLUSTER_SERVER=$3
  CLUSTER_TOKEN=$4

  cat <<EOF
apiVersion: v1
clusters:
   - cluster:
       certificate-authority-data: ${CLUSTER_CA}
       server: ${CLUSTER_SERVER}
     name: ${CLUSTER_NAME}
contexts:
   - context:
       cluster: ${CLUSTER_NAME}
       user: ${CLUSTER_NAME}
     name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
   - name: ${CLUSTER_NAME}
     user:
       token: ${CLUSTER_TOKEN}
EOF
}

# Function to wait for namespace and service account to be created.
function wait_for_objects() {
  NAMESPACE=$1
  SERVICE_ACCOUNT=$2
  
  # Objects created async by the operator may not exist yet.
  # Manual wait for object creation until this is merged: https://github.com/kubernetes/kubernetes/pull/83335
  echo "Waiting for namespace '${NAMESPACE}'"
  until [[ -n $(kubectl get namespace ${NAMESPACE} -oname 2>/dev/null) ]]; do sleep 2; done
  echo "Namespace '${NAMESPACE}' is ready"

  echo "Waiting for service account '${SERVICE_ACCOUNT}'"
  until [[ -n $(kubectl get -n ${NAMESPACE} serviceaccount ${SERVICE_ACCOUNT} -oname 2>/dev/null) ]]; do sleep 2; done
  echo "Service account '${SERVICE_ACCOUNT}' is ready"
}

# Builds cluster config and saves it to new secret for the given context.
function add_cluster_config() {
  CONTEXT=$1
  DEST_DIR=$2
  NAMESPACE=${3:-"istio-system"}
  SERVICE_ACCOUNT=${4:-"istio-reader-service-account"}

  kubectl config use-context ${CONTEXT}

  wait_for_objects ${NAMESPACE} ${SERVICE_ACCOUNT}

  CLUSTER_NAME=$(kubectl config view --minify=true -o "jsonpath={.clusters[].name}")
  CLUSTER_NAME="${CLUSTER_NAME##*_}"
  SERVER=$(kubectl config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
  SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
  CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
  TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['token']}" | base64 -d)

  build_cluster_config ${CLUSTER_NAME} "${CA_DATA}" "${SERVER}" "${TOKEN}" | \
    kubectl create secret generic ${CLUSTER_NAME} --dry-run -o yaml --from-file=${CONTEXT}=/dev/stdin \
      > ${DEST_DIR}/${CONTEXT}-secret.yaml
    (cd ${DEST_DIR} && kustomize edit add resource ${CONTEXT}-secret.yaml)
}

DEST_DIR=".kubeconfigs"

# Config for dev1-gke-1 cluster
add_cluster_config ${DEV1_GKE_1} ${DEST_DIR}

# Config for dev1-gke-2 cluster
add_cluster_config ${DEV1_GKE_2} ${DEST_DIR}

# Config for dev2-gke-1 cluster
add_cluster_config ${DEV2_GKE_1} ${DEST_DIR}

# Config for dev2-gke-2 cluster
add_cluster_config ${DEV2_GKE_2} ${DEST_DIR}

for cluster in ${OPS_GKE_1} ${OPS_GKE_2}; do
  # Apply the kustomization to the ops cluster
  kubectl config use-context ${cluster}
  kubectl apply -k ${DEST_DIR}
done