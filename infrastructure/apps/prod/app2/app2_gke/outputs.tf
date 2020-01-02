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

output "dev2_gke_3_name" { value = "${module.create_gke_3_dev2_r2a_subnet_04.name}" }
output "dev2_gke_3_location" { value = "${module.create_gke_3_dev2_r2a_subnet_04.location}" }

output "dev2_gke_4_name" { value = "${module.create_gke_4_dev2_r2b_subnet_04.name}" }
output "dev2_gke_4_location" { value = "${module.create_gke_4_dev2_r2b_subnet_04.location}" }
