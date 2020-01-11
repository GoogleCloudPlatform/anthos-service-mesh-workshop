apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: SVC_NAME
  namespace: SVC_NAMESPACE
spec:
  host: SVC_NAME.SVC_NAMESPACE.svc.cluster.local
  subsets:
  - name: OLD_VERSION
    labels:
      version: OLD_VERSION
  - name: NEW_VERSION
    labels:
      version: NEW_VERSION