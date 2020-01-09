apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: frontend
  namespace: frontend
spec:
  host: frontend
  subsets:
  - name: NEW_VERSION
    labels:
      version: NEW_VERSION