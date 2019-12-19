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
