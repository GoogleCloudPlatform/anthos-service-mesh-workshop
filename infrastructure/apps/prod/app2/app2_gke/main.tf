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

data "google_container_engine_versions" "r2a_subnet_04" {
  project        = data.terraform_remote_state.app2_project.outputs.dev2_project_id
  location       = "${var.subnet_04_region}-a"
  version_prefix = var.kubernetes_version
}

data "google_container_engine_versions" "r2b_subnet_04" {
  project        = data.terraform_remote_state.app2_project.outputs.dev2_project_id
  location       = "${var.subnet_04_region}-b"
  version_prefix = var.kubernetes_version
}


# gke-3-apps-r2a-prod - Create GKE zonal cluster in dev2 project using subnet-04 zone a
module "create_gke_3_dev2_r2a_subnet_04" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v5.1.1"
  project_id         = data.terraform_remote_state.app2_project.outputs.dev2_project_id
  name               = var.gke_dev2-r2a
  kubernetes_version = data.google_container_engine_versions.r2a_subnet_04.latest_master_version
  region             = var.subnet_04_region
  regional           = false
  zones              = ["${var.subnet_04_region}-a"]
  network_project_id = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  network            = data.terraform_remote_state.shared_vpc.outputs.network_name
  subnetwork         = var.subnet_04_name
  ip_range_pods      = var.subnet_04_secondary_pod_name
  ip_range_services  = var.subnet_04_secondary_svc_1_name
  network_policy     = true
  node_metadata      = "GKE_METADATA_SERVER"
  identity_namespace = "${data.terraform_remote_state.app2_project.outputs.dev2_project_id}.svc.id.goog"
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
      initial_node_count = 3
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}


# gke-4-apps-r2b-prod - Create GKE zonal cluster in dev2 project using subnet-04 zone b
module "create_gke_4_dev2_r2b_subnet_04" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v5.1.1"
  project_id         = data.terraform_remote_state.app2_project.outputs.dev2_project_id
  name               = var.gke_dev2-r2b
  kubernetes_version = data.google_container_engine_versions.r2b_subnet_04.latest_master_version
  region             = var.subnet_04_region
  regional           = false
  zones              = ["${var.subnet_04_region}-b"]
  network_project_id = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  network            = data.terraform_remote_state.shared_vpc.outputs.network_name
  subnetwork         = var.subnet_04_name
  ip_range_pods      = var.subnet_04_secondary_pod_name
  ip_range_services  = var.subnet_04_secondary_svc_2_name
  network_policy     = true
  node_metadata      = "GKE_METADATA_SERVER"
  identity_namespace = "${data.terraform_remote_state.app2_project.outputs.dev2_project_id}.svc.id.goog"
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
      initial_node_count = 3
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
resource "null_resource" "exec_check_for_cloudbuild_service_accounts_in_app2_project" {
  provisioner "local-exec" {
    command = <<EOT
      for (( c=1; c<=40; c++))
        do
          CHECK=`gcloud projects get-iam-policy ${data.terraform_remote_state.app2_project.outputs.dev2_project_id} --format=json | jq '.bindings[]' | jq -r '. | select(.role == "roles/container.serviceAgent").members[]'`

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
resource "google_project_iam_member" "ops_cloudbuild_sa_gke_admin_in_app2_project" {
  project = data.terraform_remote_state.app2_project.outputs.dev2_project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${data.terraform_remote_state.ops_project.outputs.ops_project_number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    null_resource.exec_check_for_cloudbuild_service_accounts_in_app2_project
  ]
}

# Give ops Cloudbuild SA clusteradmin role to the ops clusters
resource "null_resource" "exec_gke_clusteradmin_app2" {
  provisioner "local-exec" {
    command = <<EOT
    gcloud container clusters get-credentials "${module.create_gke_3_dev2_r2a_subnet_04.name}" --zone "${var.subnet_04_region}-a" --project "${data.terraform_remote_state.app2_project.outputs.dev2_project_id}"
    gcloud container clusters get-credentials "${module.create_gke_4_dev2_r2b_subnet_04.name}" --zone "${var.subnet_04_region}-b" --project "${data.terraform_remote_state.app2_project.outputs.dev2_project_id}"
    kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account) --user=${var.project_editor} --dry-run -oyaml | kubectl apply --context gke_"${data.terraform_remote_state.app2_project.outputs.dev2_project_id}"_"${var.subnet_04_region}-a"_"${module.create_gke_3_dev2_r2a_subnet_04.name}" -f -
    kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account) --user=${var.project_editor} --dry-run -oyaml | kubectl apply --context gke_"${data.terraform_remote_state.app2_project.outputs.dev2_project_id}"_"${var.subnet_04_region}-b"_"${module.create_gke_4_dev2_r2b_subnet_04.name}" -f -
    EOT

    environment = {
      KUBECONFIG = "kubemesh"
    }
  }
  depends_on = [
    module.create_gke_3_dev2_r2a_subnet_04,
    module.create_gke_4_dev2_r2b_subnet_04,
    google_project_iam_member.ops_cloudbuild_sa_gke_admin_in_app2_project,
  ]
}

# Service account used by CNRM.
resource "google_service_account" "cnrm-system" {
  project      = data.terraform_remote_state.app2_project.outputs.dev2_project_id
  account_id   = "cnrm-system"
  display_name = "cnrm-system"
  depends_on = [
    null_resource.exec_check_for_cloudbuild_service_accounts_in_app2_project
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
    module.create_gke_3_dev2_r2a_subnet_04,
    module.create_gke_4_dev2_r2b_subnet_04
  ]
}
