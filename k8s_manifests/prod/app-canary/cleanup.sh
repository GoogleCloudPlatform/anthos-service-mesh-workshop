#!/bin/bash

kubectl --context ${DEV1_GKE_1} delete -n frontend deployment frontend-v2
kubectl --context ${DEV1_GKE_2} delete -n frontend deployment frontend-v2
kubectl --context ${DEV2_GKE_1} delete -n frontend deployment frontend-v2
kubectl --context ${DEV2_GKE_2} delete -n frontend deployment frontend-v2

kubectl --context ${DEV1_GKE_1} delete -n frontend deployment respy
kubectl --context ${DEV2_GKE_1} delete -n frontend deployment respy

kubectl --context ${OPS_GKE_1} delete -n frontend destinationrule frontend
kubectl --context ${OPS_GKE_2} delete -n frontend destinationrule frontend

kubectl --context ${OPS_GKE_1} delete -n frontend virtualservice frontend
kubectl --context ${OPS_GKE_2} delete -n frontend virtualservice frontend
