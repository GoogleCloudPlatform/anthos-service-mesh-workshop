#!/bin/sh

kubectl --context ${CLUSTER} patch deployment frontend -n frontend --patch '{"spec": {"template": {"metadata": {"labels": {"version": "v1"}}}}}'
kubectl --context ${CLUSTER} patch deployment frontend -n frontend --patch \ '{"spec":{"template":{"spec":{"containers":[{"name":"server","image":"meganokeefe/frontend:v1"}]}}}}'
sed "s/NEW_VERSION/v2/g" ./setup/deployment.yaml.tpl > ./setup/frontend-deployment-v2.yaml
cp ./setup/frontend-deployment-v2.yaml ../../../anthos-service-mesh-lab/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/deployments
cp ./setup/respy.yaml ../../../anthos-service-mesh-lab/k8s-repo/${DEV1_GKE_1_CLUSTER}/app/deployments
cd ../../../anthos-service-mesh-lab/k8s-repo/; git add .; git commit -m "Frontend v2 Canary setup - ${CLUSTER}"; git push origin master

kubectl --context ${CLUSTER} wait --for=condition=available --timeout=600s deployment/frontend-v2 -n frontend
