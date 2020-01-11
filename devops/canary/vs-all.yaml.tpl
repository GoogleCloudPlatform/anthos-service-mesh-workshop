apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: SVC_NAME
  namespace: SVC_NAMESPACE
spec:
  hosts:
  - SVC_NAME.SVC_NAMESPACE.svc.cluster.local
  http:
  - route:
    - destination:
        host: SVC_NAME
        subset: VERSION
        port:
          number: SVC_PORT
      weight: 100