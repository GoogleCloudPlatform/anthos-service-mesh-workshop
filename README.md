# Abstract
This workshop is a hands-on immersive experience that goes through how to set up globally distributed services on GCP in production. The main technologies used are Google Kubernetes Engine (GKE) for compute and Istio service mesh to create secure connectivity, observability, and advanced traffic shaping. All the practices and tools used in this workshop are what you would use in production.

# Agenda
## Module 0: Infrastructure Setup
* GCP Infrastructure setup
  * Set up GCP projects, shared VPC and GKE clusters using Terraform. Refer to the architecture diagram.
* Istio Install
  * Install one Istio control plane per region (on a regional GKE cluster) using Istio CNI with PodSecurityPolicy enabled on all GKE clusters.
  * Install Istio remote on application clusters.
## Module 1: Applications
* Application deployment
  * Deploy Hipster Shop app on the application clusters.
* Observability
  * Setup monitoring and dashboards in Stackdriver
  * Logging, metrics and distributed tracing
  * Kiali topology graphs
  * Precreated charts in Grafana
  * Set up alerts
* Security
  * Configure mTLS for Service-to-Service communication within the mesh
  * Connectivity to non-mesh services
  * Securing Istio Ingress using managed certs and IAP
* Multicluster Ingress (to frontends running in multiple clusters in multiple regions)
  * Outbound to external services (to services not in the service mesh for example, a database or Google APIs).
  * Inbound to an internal mesh service (from services not in the service mesh using JWT tokens)
## Module 2: DevOps
* App rollouts using canary releases
  * Integrate Istio resources into a CI/CD pipeline 
  * Code, config and policy rollouts
  * Policy and RBAC
* App migration
  * Migrate a service from GCE VM to GKE using Istio
## Module 3: InfraOps
* Upgrades
  * GKE and Istio/ASM 
* Scaling
  * Add GKE clusters in a region
  * Add new teams/apps (i.e. projects)
  * Add new regions to an existing team
* Troubleshooting and monitoring
  * Control plane dashboards
  * Istio troubleshooting
* Resiliency and Hardening
  * Circuit breaking
  * Testing in production (traffic mirroring for A/B testing, fault injection for chaos testing)
## Prerequisites
* The following are required before you proceed with this workshop:
  * A GCP Organization node
  * GCP Organization ID
  * A billing account ID (your user must be Billing Admin on this billing account)
  * Organization Administrator IAM role at the Org level for your user
