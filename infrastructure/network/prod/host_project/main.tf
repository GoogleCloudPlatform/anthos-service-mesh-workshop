###################  NETWORK HOST PROJECT  #######################
# create network host project
module "create_host_project" {
  source          = "terraform-google-modules/project-factory/google"
  version         = "4.0.1"
  billing_account = var.billing_account
  name            = var.host_project_name
  org_id          = var.org_id
  folder_id       = var.folder_id

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
}
