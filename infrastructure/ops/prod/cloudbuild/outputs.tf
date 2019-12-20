output "k8s_repo_name" { value = google_sourcerepo_repository.k8s_repo.name }
output "cloudbuild_yaml_sha1" { value = sha1(data.template_file.cloudbuild_yaml.rendered) }