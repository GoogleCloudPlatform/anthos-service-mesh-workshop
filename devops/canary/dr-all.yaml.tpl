apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: SVC_NAME
spec:
  host: SVC_NAME.SVC_NAMESPACE.svc.cluster.local
  subsets:
  - name: NEW_VERSION
    labels:
      version: NEW_VERSION