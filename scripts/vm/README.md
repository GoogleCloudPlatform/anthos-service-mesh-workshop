End goal: 2 VMs, eventually just 1, ONLY in the Dev1 region. leave Dev2 region alone.

To start:
- add network tags
- get hostname vars for both VMs using jq (?)
- create k8s to gce firewall rules - FOUR TOTAL, from both dev1 clusters
- delete all services AND deployments for payments

## jq name

```
gcloud compute instances list --filter="name~'productcatalog*'" --format=json |
jq -r '.[]|select(.name | startswith("productcatalogservice2")) | .name'
```

## adding network tags

```
VM_NAME="productcatalogservice2"
VM_ZONE="us-east1-b"
TAG=${VM_NAME}
gcloud compute instances add-tags ${VM_NAME} --zone ${VM_ZONE} --tags=${TAG}
```

## steps - external / payments  [VM stays VM]
- istio sidecar + nodeagent installed
- added to the mesh with SE and istioctl register
- TODO: how will svc accounts work? can they work as before..? (is there a PSP or something?)


# steps - mesh / products  [VM to be migrated]
- istio sidecar + nodeagent installed
- added to the mesh with SE and istioctl register
- TODO: how will svc accounts work? can they work as before..? (is there a PSP or something?)
- create a VS on top of 2 k8s services. start by sending all traffic to the VM
- put productcatalog back onto the clusters, as before
- split traffic 50/50
- look at access logs for both productcatalog
- split traffic 100/0