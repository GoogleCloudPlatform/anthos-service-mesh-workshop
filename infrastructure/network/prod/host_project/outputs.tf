# project ids
    output "host_project_id" { value = "${module.create_host_project.project_id}" }
    output "folder_name" { value = "${google_folder.folder.name}"}