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

variable "target_size" { default = 1 }
variable "gce_vm_mesh_hostname" { default = "gce-vm-mesh" }
variable "gce_vm_external_hostname" { default = "gce-vm-external" }
variable "source_image_family" { default = "ubuntu-1804-lts" }
#variable "service_account" { default =
#  {
#    email = "${data.terraform_remote_state.app1_project.outputs.dev1_project_service_account_email}"
#    scopes = ["cloud-platform"]
#  }
#}
