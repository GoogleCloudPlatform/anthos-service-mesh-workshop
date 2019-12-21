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

output "dev1_gke_1_name" { value = "${module.create_gke_1_dev1_r1a_subnet_03.name}" }
output "dev1_gke_1_location" { value = "${module.create_gke_1_dev1_r1a_subnet_03.location}" }

output "dev1_gke_2_name" { value = "${module.create_gke_2_dev1_r1b_subnet_03.name}" }
output "dev1_gke_2_location" { value = "${module.create_gke_2_dev1_r1b_subnet_03.location}" }
