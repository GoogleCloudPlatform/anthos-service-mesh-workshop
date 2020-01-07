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

# create ops-asm project
module "create_ops_asm_project" {
  source          = "terraform-google-modules/project-factory/google"
  version         = "4.0.1"
  billing_account = "${var.billing_account}"
  name            = "${var.ops_project_name}"
  org_id          = "${var.org_id}"
  folder_id       = var.folder_id
  shared_vpc      = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  shared_vpc_subnets = [
    "projects/${data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id}/regions/${var.subnet_01_region}/subnetworks/${var.subnet_01_name}",
    "projects/${data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id}/regions/${var.subnet_02_region}/subnetworks/${var.subnet_02_name}",
    "projects/${data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id}/regions/${var.subnet_06_region}/subnetworks/${var.subnet_06_name}",
  ]

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com"
  ]
}

# Grant Compute Security Admin IAM role to the Kubernetes SA in the network host project
resource "google_project_iam_member" "ops_gke_sa_security_admin_in_host" {
  project = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:service-${module.create_ops_asm_project.project_number}@container-engine-robot.iam.gserviceaccount.com"

  depends_on = [
    null_resource.exec_check_for_ops_gke_service_accounts
  ]

}

# Grant project editor to the passed user
resource "google_project_iam_member" "ops_project_editor" {
  project = module.create_ops_asm_project.project_id
  role    = "roles/editor"
  member  = "user:${var.project_editor}"

  depends_on = [
    null_resource.exec_check_for_ops_gke_service_accounts
  ]
}

# Grant source repo admin to the passed user
resource "google_project_iam_member" "ops_project_source_admin" {
  project = module.create_ops_asm_project.project_id
  role    = "roles/source.admin"
  member  = "user:${var.project_editor}"

  depends_on = [
    null_resource.exec_check_for_ops_gke_service_accounts
  ]
}

resource "null_resource" "exec_check_for_ops_gke_service_accounts" {
  provisioner "local-exec" {
    command = <<EOT
      for (( c=1; c<=40; c++))
        do
          CHECK1=`gcloud projects get-iam-policy ${module.create_ops_asm_project.project_id} --format=json | jq '.bindings[]' | jq -r '. | select(.role == "roles/container.serviceAgent").members[]'`
          if [[ "$CHECK1" ]]; then
            echo "GKE service accounts created."
            break;
          fi

          echo "Waiting for GKE service accounts to be created."
          sleep 2
        done
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}
