apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
  namespace: frontend
spec:
  hosts:
  - frontend
  http:
  - route:
    - destination:
        host: frontend
        subset: NEW_VERSION
        port:
          number: 80
      weight: 100