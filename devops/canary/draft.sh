#!/bin/sh

# vars:
OLD_VERSION
NEW_VERSION
OPS_CLUSTER = where Istio is
DEV_CLUSTER = where the workloads are
DEV_NAMESPACE = k8s namespace on the dev cluster where the app lives

# patch in new image with /version endpoint, apply the v1 label to the existing frontend on dev cluster 1
kubectl patch deployment frontend -n default --patch '{"spec": {"template": {"metadata": {"labels": {"version": "v1"}}}}}'
kubectl patch deployment frontend -n default --patch \
  '{"spec":{"template":{"spec":{"containers":[{"name":"server","image":"meganokeefe/frontend:v1"}]}}}}'

# generate v2 deployment with sed
sed "s/NEW_VERSION/${_NEW_VERSION}/g" ./setup/deployment.yaml.tpl > ./setup/deployment.yaml

# copy v2 deployment, respy into the dev directory for cluster 1  - push to k8s repo
cp -r ./setup/deployment.yaml ../k8s-repo/${DEV1_GKE_1_CLUSTER}/app/
cd ../k8s-repo; git add .; git commit -m "Frontend v2 Canary"; git push origin master;

# wait for k8s repo build to complete, get pods - should see 3 total. v1, v2, respy
kubectl --context ${DEV1_GKE_1} get pods -n frontend

# submit canary build manually

# exec into respy pod


# remove respy and old version deployment by deleting files and pushing to k8s-repo


# repeat steps for other clusters with a script
# watch them in cloud build --> wait for complete

# get frontend pods across all namespace. should be v2 across the board