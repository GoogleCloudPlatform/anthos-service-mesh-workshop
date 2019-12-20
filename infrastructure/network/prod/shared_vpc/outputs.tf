# Network outputs
output "svpc_host_project_id" { value = "${module.create_vpc_in_host_project.svpc_host_project_id}" }
output "subnets_self_links" { value = "${module.create_vpc_in_host_project.subnets_self_links}" }
output "subnets_names" { value = "${module.create_vpc_in_host_project.subnets_names}" }
output "network_name" { value = "${module.create_vpc_in_host_project.network_name}" }
output "network_self_link" { value = "${module.create_vpc_in_host_project.network_self_link}" }