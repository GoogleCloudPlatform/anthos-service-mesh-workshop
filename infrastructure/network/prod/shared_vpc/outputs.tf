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

# Network outputs
output "svpc_host_project_id" { value = "${module.create_vpc_in_host_project.svpc_host_project_id}" }
output "subnets_self_links" { value = "${module.create_vpc_in_host_project.subnets_self_links}" }
output "subnets_names" { value = "${module.create_vpc_in_host_project.subnets_names}" }
output "network_name" { value = "${module.create_vpc_in_host_project.network_name}" }
output "network_self_link" { value = "${module.create_vpc_in_host_project.network_self_link}" }
