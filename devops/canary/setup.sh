#!/bin/sh

kubectl delete deployment frontend -n frontend
kubectl apply -f ./baseline/ -n frontend