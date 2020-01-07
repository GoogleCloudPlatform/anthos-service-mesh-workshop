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

output "ops_gke_1_name" { value = "${module.create_gke_1_ops_asm_subnet_01.name}" }
output "ops_gke_1_location" { value = "${module.create_gke_1_ops_asm_subnet_01.location}" }

output "ops_gke_2_name" { value = "${module.create_gke_2_ops_asm_subnet_02.name}" }
output "ops_gke_2_location" { value = "${module.create_gke_2_ops_asm_subnet_02.location}" }

output "ops_gke_3_name" { value = "${module.create_gke_3_ops_asm_subnet_06.name}" }
output "ops_gke_3_location" { value = "${module.create_gke_3_ops_asm_subnet_06.location}" }

output "ops_gke_1_policy_ilb_address" { value = local.ops_gke_1_policy_ilb_address }
output "ops_gke_1_telemetry_ilb_address" { value = local.ops_gke_1_telemetry_ilb_address }
output "ops_gke_1_pilot_ilb_address" { value = local.ops_gke_1_pilot_ilb_address }

output "ops_gke_2_policy_ilb_address" { value = local.ops_gke_2_policy_ilb_address }
output "ops_gke_2_telemetry_ilb_address" { value = local.ops_gke_2_telemetry_ilb_address }
output "ops_gke_2_pilot_ilb_address" { value = local.ops_gke_2_pilot_ilb_address }

output "ops_gke_3_policy_ilb_address" { value = local.ops_gke_3_policy_ilb_address }
output "ops_gke_3_telemetry_ilb_address" { value = local.ops_gke_3_telemetry_ilb_address }
output "ops_gke_3_pilot_ilb_address" { value = local.ops_gke_3_pilot_ilb_address }
