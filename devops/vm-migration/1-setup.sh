# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

source ./env.sh

# install Istio -- TODO -- remove / move to setup
# ISTIO_VERSION="${ISTIO_VERSION:-1.4.2}"
# curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
# kubectl label namespace default istio-injection=enabled
# kubectl create namespace istio-system
# kubectl create clusterrolebinding cluster-admin-binding \
#     --clusterrole=cluster-admin \
#     --user=$(gcloud config get-value core/account)
# helm template ${WORKDIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
# sleep 20

# helm template ${WORKDIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --name istio --namespace istio-system \
# --set prometheus.enabled=true \
# --set tracing.enabled=true \
# --set kiali.enabled=true --set kiali.createDemoSecret=true \
# --set "kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
# --set "kiali.dashboard.grafanaURL=http://grafana:3000" \
# --set grafana.enabled=true \
# --set global.meshExpansion.enabled=true \
# --set global.proxy.accessLogFile="/dev/stdout" >> istio.yaml

# kubectl apply -f istio.yaml

# create firewall rule (cluster->VM), then start VM
K8S_POD_CIDR=$(gcloud container clusters describe ${CLUSTER_NAME?} --zone ${CLUSTER_ZONE?} --format=json | jq -r '.clusterIpv4Cidr')

gcloud compute firewall-rules create k8s-to-products-gce \
--description="Allow k8s pods CIDR to istio-gce instance" \
--source-ranges=$K8S_POD_CIDR \
--target-tags=${VM_NAME} \
--action=ALLOW \
--rules=tcp:${VM_PORT}

gcloud compute --project=$PROJECT_ID instances create "${VM_NAME}" --zone=$VM_ZONE \
--machine-type=n1-standard-2 --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE \
--image=ubuntu-1604-xenial-v20191010 --image-project=ubuntu-os-cloud --boot-disk-size=10GB \
--boot-disk-type=pd-standard --boot-disk-device-name=$VM_NAME --tags=$VM_NAME