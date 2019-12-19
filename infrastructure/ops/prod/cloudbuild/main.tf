# Create CSR repo for k8s manifests
resource "google_sourcerepo_repository" "k8s_repo" {
  name = var.k8s_repo_name
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

# Create a cloudbuild.yaml file
resource "null_resource" "exec_make_cloudbuild_yaml" {
  provisioner "local-exec" {
    command = <<EOT
    cat > cloudbuild.yaml <<EOF
steps:
# This step deploys the manifests to the gke-asm-1-r1-prod cluster
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy-ops-asm-1
  args:
  - 'apply'
  - '-f'
  - './gke-asm-1-r1-prod'
  env:
  - 'CLOUDSDK_CORE_PROJECT=${data.terraform_remote_state.ops_project.outputs.ops_project_id}'
  - 'CLOUDSDK_COMPUTE_REGION=${data.terraform_remote_state.ops_gke.outputs.ops_gke_1_location}'
  - 'CLOUDSDK_CONTAINER_CLUSTER=${data.terraform_remote_state.ops_gke.outputs.ops_gke_1_name}'

# This step deploys the manifests to the gke-asm-2-r2-prod cluster
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy-ops-asm-2
  args:
  - 'apply'
  - '-f'
  - './gke-asm-2-r2-prod'
  env:
  - 'CLOUDSDK_CORE_PROJECT=${data.terraform_remote_state.ops_project.outputs.ops_project_id}'
  - 'CLOUDSDK_COMPUTE_REGION=${data.terraform_remote_state.ops_gke.outputs.ops_gke_2_location}'
  - 'CLOUDSDK_CONTAINER_CLUSTER=${data.terraform_remote_state.ops_gke.outputs.ops_gke_2_name}'

# This step deploys the manifests to the gke-1-apps-r1a-prod cluster
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy-gke-1-apps-r1a-prod
  args:
  - 'apply'
  - '-f'
  - './gke-1-apps-r1a-prod'
  env:
  - 'CLOUDSDK_CORE_PROJECT=${data.terraform_remote_state.app1_project.outputs.dev1_project_id}'
  - 'CLOUDSDK_COMPUTE_REGION=${data.terraform_remote_state.app1_gke.outputs.dev1_gke_1_location}'
  - 'CLOUDSDK_CONTAINER_CLUSTER=${data.terraform_remote_state.app1_gke.outputs.dev1_gke_1_name}'

# This step deploys the manifests to the gke-2-apps-r1b-prod cluster
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy-gke-2-apps-r1b-prod
  args:
  - 'apply'
  - '-f'
  - './gke-2-apps-r1b-prod'
  env:
  - 'CLOUDSDK_CORE_PROJECT=${data.terraform_remote_state.app1_project.outputs.dev1_project_id}'
  - 'CLOUDSDK_COMPUTE_REGION=${data.terraform_remote_state.app1_gke.outputs.dev1_gke_2_location}'
  - 'CLOUDSDK_CONTAINER_CLUSTER=${data.terraform_remote_state.app1_gke.outputs.dev1_gke_2_name}'

# This step deploys the manifests to the gke-3-apps-r2a-prod cluster
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy-gke-3-apps-r2a-prod
  args:
  - 'apply'
  - '-f'
  - './gke-3-apps-r2a-prod'
  env:
  - 'CLOUDSDK_CORE_PROJECT=${data.terraform_remote_state.app2_project.outputs.dev2_project_id}'
  - 'CLOUDSDK_COMPUTE_REGION=${data.terraform_remote_state.app2_gke.outputs.dev2_gke_3_location}'
  - 'CLOUDSDK_CONTAINER_CLUSTER=${data.terraform_remote_state.app2_gke.outputs.dev2_gke_3_name}'

# This step deploys the manifests to the gke-4-apps-r2b-prod cluster
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy-gke-4-apps-r2b-prod
  args:
  - 'apply'
  - '-f'
  - './gke-4-apps-r2b-prod'
  env:
  - 'CLOUDSDK_CORE_PROJECT=${data.terraform_remote_state.app2_project.outputs.dev2_project_id}'
  - 'CLOUDSDK_COMPUTE_REGION=${data.terraform_remote_state.app2_gke.outputs.dev2_gke_4_location}'
  - 'CLOUDSDK_CONTAINER_CLUSTER=${data.terraform_remote_state.app2_gke.outputs.dev2_gke_4_name}'
  EOT
  }
}

# Push cloudbuild to bucket
resource "null_resource" "exec_push_cloudbuild_yaml_to_gcs" {
  provisioner "local-exec" {
    command = <<EOT
    gsutil cp cloudbuild.yaml gs://${var.tfadmin_proj}/ops/k8s/cloudbuild.yaml
    EOT
  }
  depends_on = [
    null_resource.exec_make_cloudbuild_yaml,
  ]
}