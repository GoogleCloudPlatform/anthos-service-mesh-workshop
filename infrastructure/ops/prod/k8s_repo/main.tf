# Archive used to detect changes in repo
data "archive_file" "repo" {
  type        = "zip"
  source_dir  = "config/"
  output_path = "data.zip"
}

resource "null_resource" "exec_create_k8s_repo" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "${path.module}/build_repo.sh"
    environment = {
      tfadmin_proj            = var.tfadmin_proj
      istio_version           = var.istio_version
      k8s_repo_name           = data.terraform_remote_state.cloudbuild.outputs.k8s_repo_name
      ops_project_id          = data.terraform_remote_state.ops_project.outputs.ops_project_id
      dev1_project_id         = data.terraform_remote_state.app1_project.outputs.dev1_project_id
      dev2_project_id         = data.terraform_remote_state.app2_project.outputs.dev2_project_id
      dev3_project_id         = data.terraform_remote_state.app3_project.outputs.dev3_project_id
      ops_gke_1_name          = data.terraform_remote_state.ops_gke.outputs.ops_gke_1_name
      ops_gke_2_name          = data.terraform_remote_state.ops_gke.outputs.ops_gke_2_name
      ops_gke_3_name          = data.terraform_remote_state.ops_gke.outputs.ops_gke_3_name
      ops_gke_1_policy_ilb    = data.terraform_remote_state.ops_gke.outputs.ops_gke_1_policy_ilb_address
      ops_gke_1_telemetry_ilb = data.terraform_remote_state.ops_gke.outputs.ops_gke_1_telemetry_ilb_address
      ops_gke_1_pilot_ilb     = data.terraform_remote_state.ops_gke.outputs.ops_gke_1_pilot_ilb_address
      ops_gke_2_policy_ilb    = data.terraform_remote_state.ops_gke.outputs.ops_gke_2_policy_ilb_address
      ops_gke_2_telemetry_ilb = data.terraform_remote_state.ops_gke.outputs.ops_gke_2_telemetry_ilb_address
      ops_gke_2_pilot_ilb     = data.terraform_remote_state.ops_gke.outputs.ops_gke_2_pilot_ilb_address
      ops_gke_3_policy_ilb    = data.terraform_remote_state.ops_gke.outputs.ops_gke_3_policy_ilb_address
      ops_gke_3_telemetry_ilb = data.terraform_remote_state.ops_gke.outputs.ops_gke_3_telemetry_ilb_address
      ops_gke_3_pilot_ilb     = data.terraform_remote_state.ops_gke.outputs.ops_gke_3_pilot_ilb_address
      dev1_gke_1_name         = data.terraform_remote_state.app1_gke.outputs.dev1_gke_1_name
      dev1_gke_2_name         = data.terraform_remote_state.app1_gke.outputs.dev1_gke_2_name
      dev2_gke_3_name         = data.terraform_remote_state.app2_gke.outputs.dev2_gke_3_name
      dev2_gke_4_name         = data.terraform_remote_state.app2_gke.outputs.dev2_gke_4_name
      dev3_gke_5_name         = data.terraform_remote_state.app3_gke.outputs.dev3_gke_5_name
      dev3_gke_6_name         = data.terraform_remote_state.app3_gke.outputs.dev3_gke_6_name
    }
  }

  triggers = {
    script_sha1          = sha1(file("build_repo.sh"))
    data_sha1            = data.archive_file.repo.output_sha
    cloudbuild_yaml_sha1 = data.terraform_remote_state.cloudbuild.outputs.cloudbuild_yaml_sha1
  }
}
