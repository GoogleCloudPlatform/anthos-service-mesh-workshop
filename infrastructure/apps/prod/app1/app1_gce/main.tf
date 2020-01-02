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

# GCE VM for mesh expansion
module "instance_template" {
  source              = "github.com/terraform-google-modules/terraform-google-vm//modules/instance_template?ref=v1.3.0"
  project_id          = data.terraform_remote_state.app1_project.outputs.dev1_project_id
  network             = data.terraform_remote_state.shared_vpc.outputs.network_self_link
  subnetwork          = data.terraform_remote_state.shared_vpc.outputs.subnets_self_links[2]
  source_image_family = var.source_image_family
  service_account = {
    email  = data.terraform_remote_state.app1_project.outputs.dev1_project_service_account_email
    scopes = ["cloud-platform"]
  }
}

module "gce_vm_mesh" {
  source            = "github.com/terraform-google-modules/terraform-google-vm//modules/mig?ref=v1.3.0"
  project_id        = data.terraform_remote_state.app1_project.outputs.dev1_project_id
  region            = var.subnet_03_region
  target_size       = var.target_size
  hostname          = var.gce_vm_mesh_hostname
  instance_template = module.instance_template.self_link
}

module "gce_vm_external" {
  source            = "github.com/terraform-google-modules/terraform-google-vm//modules/mig?ref=v1.3.0"
  project_id        = data.terraform_remote_state.app1_project.outputs.dev1_project_id
  region            = var.subnet_03_region
  target_size       = var.target_size
  hostname          = var.gce_vm_external_hostname
  instance_template = module.instance_template.self_link
}

