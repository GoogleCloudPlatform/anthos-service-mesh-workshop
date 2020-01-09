apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: frontend
  namespace: frontend
spec:
  host: frontend
  subsets:
  - name: OLD_VERSION
    labels:
      version: OLD_VERSION
  - name: NEW_VERSION
    labels:
      version: NEW_VERSION