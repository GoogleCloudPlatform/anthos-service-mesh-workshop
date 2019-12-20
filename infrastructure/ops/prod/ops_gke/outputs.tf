output "ops_gke_1_name" { value = "${module.create_gke_1_ops_asm_subnet_01.name}" }
output "ops_gke_1_location" { value = "${module.create_gke_1_ops_asm_subnet_01.location}" }

output "ops_gke_2_name" { value = "${module.create_gke_2_ops_asm_subnet_02.name}" }
output "ops_gke_2_location" { value = "${module.create_gke_2_ops_asm_subnet_02.location}" }

output "ops_gke_1_policy_ilb_address" { value = local.ops_gke_1_policy_ilb_address }
output "ops_gke_1_telemetry_ilb_address" { value = local.ops_gke_1_telemetry_ilb_address }
output "ops_gke_1_pilot_ilb_address" { value = local.ops_gke_1_pilot_ilb_address }

output "ops_gke_2_policy_ilb_address" { value = local.ops_gke_2_policy_ilb_address }
output "ops_gke_2_telemetry_ilb_address" { value = local.ops_gke_2_telemetry_ilb_address }
output "ops_gke_2_pilot_ilb_address" { value = local.ops_gke_2_pilot_ilb_address } 