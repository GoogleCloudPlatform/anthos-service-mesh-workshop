# Create CSR repo for k8s manifests
resource "google_sourcerepo_repository" "k8s_repo" {
  name    = var.k8s_repo_name
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id
}

# Add a cloudbuild trigger for k8s manifests
resource "google_cloudbuild_trigger" "k8s_trigger" {
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id
  trigger_template {
    branch_name = var.k8s_trigger_branch_name
    repo_name   = google_sourcerepo_repository.k8s_repo.name
  }
  filename = "cloudbuild.yaml"
}

data "template_file" "cloudbuild_yaml" {
  template = file("config/cloudbuild.tpl.yaml")
  vars = {
    ops_project_id      = data.terraform_remote_state.ops_project.outputs.ops_project_id
    ops_gke_1_location  = data.terraform_remote_state.ops_gke.outputs.ops_gke_1_location
    ops_gke_1_name      = data.terraform_remote_state.ops_gke.outputs.ops_gke_1_name
    ops_gke_2_location  = data.terraform_remote_state.ops_gke.outputs.ops_gke_2_location
    ops_gke_2_name      = data.terraform_remote_state.ops_gke.outputs.ops_gke_2_name
    dev1_project_id     = data.terraform_remote_state.app1_project.outputs.dev1_project_id
    dev1_gke_1_location = data.terraform_remote_state.app1_gke.outputs.dev1_gke_1_location
    dev1_gke_1_name     = data.terraform_remote_state.app1_gke.outputs.dev1_gke_1_name
    dev1_gke_2_location = data.terraform_remote_state.app1_gke.outputs.dev1_gke_2_location
    dev1_gke_2_name     = data.terraform_remote_state.app1_gke.outputs.dev1_gke_2_name
    dev2_project_id     = data.terraform_remote_state.app2_project.outputs.dev2_project_id
    dev2_gke_3_location = data.terraform_remote_state.app2_gke.outputs.dev2_gke_3_location
    dev2_gke_3_name     = data.terraform_remote_state.app2_gke.outputs.dev2_gke_3_name
    dev2_gke_4_location = data.terraform_remote_state.app2_gke.outputs.dev2_gke_4_location
    dev2_gke_4_name     = data.terraform_remote_state.app2_gke.outputs.dev2_gke_4_name
    crd_path            = "istio-operator/crds/istio_v1alpha2_istiocontrolplane_crd.yaml"
    k8s_repo_name       = var.k8s_repo_name
  }
}

# Push cloudbuild to bucket
resource "null_resource" "exec_push_cloudbuild_yaml_to_gcs" {
  provisioner "local-exec" {
    command = <<EOT
    echo "${data.template_file.cloudbuild_yaml.rendered}" | gsutil cp - gs://${var.tfadmin_proj}/ops/k8s/cloudbuild.yaml
    EOT
  }
  triggers = {
    data = data.template_file.cloudbuild_yaml.rendered
  }
}