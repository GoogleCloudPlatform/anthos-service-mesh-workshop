#!/bin/sh

kubectl delete deployment frontend
kubectl apply -f ./baseline/
