# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "google_container_engine_versions" "subnet_01" {
  project        = data.terraform_remote_state.ops_project.outputs.ops_project_id
  location       = var.subnet_01_region
  version_prefix = var.kubernetes_version
}

data "google_container_engine_versions" "subnet_02" {
  project        = data.terraform_remote_state.ops_project.outputs.ops_project_id
  location       = var.subnet_02_region
  version_prefix = var.kubernetes_version
}

# gke-asm-1-r1-prod - Create GKE regional cluster in ops-asm project using subnet-01
module "create_gke_1_ops_asm_subnet_01" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v5.1.1"
  project_id         = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name               = var.gke_asm_r1
  kubernetes_version = data.google_container_engine_versions.subnet_01.latest_master_version
  region             = var.subnet_01_region
  zones              = ["${var.subnet_01_region}-a", "${var.subnet_01_region}-b", "${var.subnet_01_region}-c"]
  network_project_id = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  network            = data.terraform_remote_state.shared_vpc.outputs.network_name
  subnetwork         = var.subnet_01_name
  ip_range_pods      = var.subnet_01_secondary_pod_name
  ip_range_services  = var.subnet_01_secondary_svc_1_name
  network_policy     = true
  node_metadata      = "GKE_METADATA_SERVER"
  identity_namespace = "${data.terraform_remote_state.ops_project.outputs.ops_project_id}.svc.id.goog"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  pod_security_policy_config = [{
    enabled = true
  }]

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 3
      max_count          = 10
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = false
      preemptible        = false
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

# gke-asm-2-r2-prod - Create GKE regional cluster in ops-asm project using subnet-02
module "create_gke_2_ops_asm_subnet_02" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v5.1.1"
  project_id         = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name               = var.gke_asm_r2
  kubernetes_version = data.google_container_engine_versions.subnet_02.latest_master_version
  region             = var.subnet_02_region
  zones              = ["${var.subnet_02_region}-a", "${var.subnet_02_region}-b", "${var.subnet_02_region}-c"]
  network_project_id = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  network            = data.terraform_remote_state.shared_vpc.outputs.network_name
  subnetwork         = var.subnet_02_name
  ip_range_pods      = var.subnet_02_secondary_pod_name
  ip_range_services  = var.subnet_02_secondary_svc_1_name
  network_policy     = true
  node_metadata      = "GKE_METADATA_SERVER"
  identity_namespace = "${data.terraform_remote_state.ops_project.outputs.ops_project_id}.svc.id.goog"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  pod_security_policy_config = [{
    enabled = true
  }]

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 3
      max_count          = 10
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = false
      preemptible        = false
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

# gke-asm-3-r3-prod - Create GKE regional cluster in ops-asm project using subnet-06
module "create_gke_3_ops_asm_subnet_06" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v5.1.1"
  project_id         = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name               = var.gke_asm_r3
  kubernetes_version = var.kubernetes_version
  region             = var.subnet_06_region
  zones              = ["${var.subnet_06_region}-b", "${var.subnet_06_region}-c", "${var.subnet_06_region}-d"]
  network_project_id = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  network            = data.terraform_remote_state.shared_vpc.outputs.network_name
  subnetwork         = var.subnet_06_name
  ip_range_pods      = var.subnet_06_secondary_pod_name
  ip_range_services  = var.subnet_06_secondary_svc_1_name
  network_policy     = true
  node_metadata      = "GKE_METADATA_SERVER"
  identity_namespace = "${data.terraform_remote_state.ops_project.outputs.ops_project_id}.svc.id.goog"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  pod_security_policy_config = [{
    enabled = true
  }]

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 3
      max_count          = 10
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = false
      preemptible        = false
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
# Check Cloudbuild SA is created
resource "null_resource" "exec_check_for_cloudbuild_service_accounts_in_ops_project" {
  provisioner "local-exec" {
    command = <<EOT
      for (( c=1; c<=40; c++))
        do
          CHECK=`gcloud projects get-iam-policy ${data.terraform_remote_state.ops_project.outputs.ops_project_id} --format=json | jq '.bindings[]' | jq -r '. | select(.role == "roles/container.serviceAgent").members[]'`

          if [[ "$CHECK" ]]; then
            echo "Cloud Build service account created."
            break;
          fi

          echo "Waiting for Cloud Build service account to be created."
          sleep 2
        done
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Add IAM container.developer role to the ops proj Cloudbuild SA in the ops project
resource "google_project_iam_member" "ops_cloudbuild_sa_gke_admin_in_ops_project" {
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${data.terraform_remote_state.ops_project.outputs.ops_project_number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    null_resource.exec_check_for_cloudbuild_service_accounts_in_ops_project
  ]
}

# Give ops Cloudbuild SA clusteradmin role to the ops clusters
resource "null_resource" "exec_gke_clusteradmin_ops" {
  provisioner "local-exec" {
    command = <<EOT
    gcloud container clusters get-credentials "${module.create_gke_1_ops_asm_subnet_01.name}" --region "${module.create_gke_1_ops_asm_subnet_01.region}" --project "${data.terraform_remote_state.ops_project.outputs.ops_project_id}"
    gcloud container clusters get-credentials "${module.create_gke_2_ops_asm_subnet_02.name}" --region "${module.create_gke_2_ops_asm_subnet_02.region}" --project "${data.terraform_remote_state.ops_project.outputs.ops_project_id}"
    gcloud container clusters get-credentials "${module.create_gke_3_ops_asm_subnet_06.name}" --region "${module.create_gke_3_ops_asm_subnet_06.region}" --project "${data.terraform_remote_state.ops_project.outputs.ops_project_id}"
    kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account) --user=${var.project_editor} --dry-run -oyaml | kubectl apply --context gke_"${data.terraform_remote_state.ops_project.outputs.ops_project_id}"_"${module.create_gke_1_ops_asm_subnet_01.region}"_"${module.create_gke_1_ops_asm_subnet_01.name}" -f -
    kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account) --user=${var.project_editor} --dry-run -oyaml | kubectl apply --context gke_"${data.terraform_remote_state.ops_project.outputs.ops_project_id}"_"${module.create_gke_2_ops_asm_subnet_02.region}"_"${module.create_gke_2_ops_asm_subnet_02.name}" -f -
    kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account) --user=${var.project_editor} --dry-run -oyaml | kubectl apply --context gke_"${data.terraform_remote_state.ops_project.outputs.ops_project_id}"_"${module.create_gke_3_ops_asm_subnet_06.region}"_"${module.create_gke_3_ops_asm_subnet_06.name}" -f -
    EOT

    environment = {
      KUBECONFIG = "kubemesh"
    }
  }
  depends_on = [
    module.create_gke_1_ops_asm_subnet_01,
    module.create_gke_2_ops_asm_subnet_02,
    module.create_gke_3_ops_asm_subnet_06,
    google_project_iam_member.ops_cloudbuild_sa_gke_admin_in_ops_project,
  ]
}

# Service account used by CNRM.
resource "google_service_account" "cnrm-system" {
  project      = data.terraform_remote_state.ops_project.outputs.ops_project_id
  account_id   = "cnrm-system"
  display_name = "cnrm-system"
  depends_on = [
    null_resource.exec_check_for_cloudbuild_service_accounts_in_ops_project
  ]
}

# IAM binding to grant CNRM service account access to the project.
resource "google_project_iam_member" "cnrm-owner" {
  project = google_service_account.cnrm-system.project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.cnrm-system.email}"
}

# Workload Identity IAM binding for CNRM.
resource "google_service_account_iam_member" "cnrm-sa-workload-identity" {
  service_account_id = google_service_account.cnrm-system.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${google_service_account.cnrm-system.project}.svc.id.goog[cnrm-system/cnrm-controller-manager]"
  depends_on = [
    module.create_gke_1_ops_asm_subnet_01,
    module.create_gke_2_ops_asm_subnet_02,
    module.create_gke_3_ops_asm_subnet_06,
  ]
}

# Grant Compute Security Admin IAM role to the CNRM system SA on the host project to allow creation of shared VPC network resources.
resource "google_project_iam_member" "cnrm_sa_security_admin_in_host" {
  project = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.cnrm-system.email}"
}

# Service account used by autoneg controller.
resource "google_service_account" "autoneg-system" {
  project      = data.terraform_remote_state.ops_project.outputs.ops_project_id
  account_id   = "autoneg-system"
  display_name = "autoneg-system"
  depends_on = [
    null_resource.exec_check_for_cloudbuild_service_accounts_in_ops_project
  ]
}

resource "google_project_iam_custom_role" "autoneg" {
  project     = data.terraform_remote_state.ops_project.outputs.ops_project_id
  role_id     = "autoneg"
  title       = "AutoNEG Custom Role"
  description = "AutoNEG controller"
  permissions = [
    "compute.backendServices.get",
    "compute.backendServices.update",
    "compute.networkEndpointGroups.use",
    "compute.healthChecks.useReadOnly"
  ]
}

# IAM binding to grant AutoNEG service account access to the project.
resource "google_project_iam_member" "autoneg-system" {
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id
  role    = "projects/${google_project_iam_custom_role.autoneg.project}/roles/${google_project_iam_custom_role.autoneg.role_id}"
  member  = "serviceAccount:${google_service_account.autoneg-system.email}"
}

# Workload Identity IAM binding for AutoNEG controller.
resource "google_service_account_iam_member" "autoneg-sa-workload-identity" {
  service_account_id = google_service_account.autoneg-system.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${google_service_account.autoneg-system.project}.svc.id.goog[autoneg-system/autoneg-system]"
  depends_on = [
    module.create_gke_1_ops_asm_subnet_01,
    module.create_gke_2_ops_asm_subnet_02
  ]
}

# Service account used by istio-telemetry (mixer).
resource "google_service_account" "istio-telemetry" {
  project      = data.terraform_remote_state.ops_project.outputs.ops_project_id
  account_id   = "istio-telemetry"
  display_name = "istio-telemetry"
  depends_on = [
    null_resource.exec_check_for_cloudbuild_service_accounts_in_ops_project
  ]
}

# IAM binding to grant istio-telemetry service account access to the project.
resource "google_project_iam_member" "istio-telemetry-owner" {
  project = google_service_account.istio-telemetry.project
  role    = "roles/owner" # narrow this down: metrics.write, logs.write, traces.write, contextgraph.write? debug/profiler?
  member  = "serviceAccount:${google_service_account.istio-telemetry.email}"
}

# Workload Identity IAM binding for istio-telemetry.
resource "google_service_account_iam_member" "istio-telemetry-sa-workload-identity" {
  service_account_id = google_service_account.istio-telemetry.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${google_service_account.istio-telemetry.project}.svc.id.goog[istio-system/istio-mixer-service-account]"
  depends_on = [
    module.create_gke_1_ops_asm_subnet_01,
    module.create_gke_2_ops_asm_subnet_02
  ]
}

# Use internal IP reservations when issue with using reserved internal IPs with K8s services:
#  https://github.com/kubernetes/kubernetes/issues/66762
locals {
  // TODO: compute these from the CIDR range variables in the host project.
  ops_gke_1_policy_ilb_address    = "10.4.1.1"
  ops_gke_1_telemetry_ilb_address = "10.4.1.2"
  ops_gke_1_pilot_ilb_address     = "10.4.1.3"
  ops_gke_2_policy_ilb_address    = "10.12.1.1"
  ops_gke_2_telemetry_ilb_address = "10.12.1.2"
  ops_gke_2_pilot_ilb_address     = "10.12.1.3"
  ops_gke_3_policy_ilb_address    = "10.44.1.1"
  ops_gke_3_telemetry_ilb_address = "10.44.1.2"
  ops_gke_3_pilot_ilb_address     = "10.44.1.3"
}

/*
resource "google_compute_address" "gke_1_ops_istio_policy_ilb" {
  project      = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  name         = "${var.gke_asm_r1}-istio-policy-ilb"
  subnetwork   = var.subnet_01_name
  address_type = "INTERNAL"
  region       = var.subnet_01_region
}

resource "google_compute_address" "gke_2_ops_istio_policy_ilb" {
  project      = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  name         = "${var.gke_asm_r2}-istio-policy-ilb"
  subnetwork   = var.subnet_02_name
  address_type = "INTERNAL"
  region       = var.subnet_02_region
}

resource "google_compute_address" "gke_1_ops_istio_telemetry_ilb" {
  project      = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  name         = "${var.gke_asm_r1}-istio-telemetry-ilb"
  subnetwork   = var.subnet_01_name
  address_type = "INTERNAL"
  region       = var.subnet_01_region
}

resource "google_compute_address" "gke_2_ops_istio_telemetry_ilb" {
  project      = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  name         = "${var.gke_asm_r2}-istio-telemetry-ilb"
  subnetwork   = var.subnet_02_name
  address_type = "INTERNAL"
  region       = var.subnet_02_region
}

resource "google_compute_address" "gke_1_ops_istio_pilot_ilb" {
  project      = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  name         = "${var.gke_asm_r1}-istio-pilot-ilb"
  subnetwork   = var.subnet_01_name
  address_type = "INTERNAL"
  region       = var.subnet_01_region
}

resource "google_compute_address" "gke_2_ops_istio_pilot_ilb" {
  project      = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  name         = "${var.gke_asm_r2}-istio-pilot-ilb"
  subnetwork   = var.subnet_02_name
  address_type = "INTERNAL"
  region       = var.subnet_02_region
}
*/
