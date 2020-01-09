#!/bin/sh

kubectl --context=${CLUSTER} delete deployment frontend -n frontend
kubectl --context=${CLUSTER} apply -f ./baseline/ -n frontend

