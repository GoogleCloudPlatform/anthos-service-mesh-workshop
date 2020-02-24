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

# vpc
variable "network_name" { default = "shared-vpc" }
variable "routing_mode" { default = "GLOBAL" }

# subnets
variable "subnet_01_name" { default = "ops-subnet-01" }
variable "subnet_01_ip" { default = "10.4.0.0/22" }
variable "subnet_01_region" { default = "us-west1" }
variable "subnet_01_description" { default = "ops-subnet-01 primary" }
variable "subnet_01_secondary_svc_1_name" { default = "ops-subnet-01-svc-1" }
variable "subnet_01_secondary_svc_1_range" { default = "10.5.0.0/20" }
variable "subnet_01_secondary_svc_2_name" { default = "ops-subnet-01-svc-2" }
variable "subnet_01_secondary_svc_2_range" { default = "10.5.16.0/20" }
variable "subnet_01_secondary_pod_name" { default = "ops-subnet-01-pod" }
variable "subnet_01_secondary_pod_range" { default = "10.0.0.0/14" }

variable "subnet_02_name" { default = "ops-subnet-02" }
variable "subnet_02_ip" { default = "10.12.0.0/22" }
variable "subnet_02_region" { default = "us-central1" }
variable "subnet_02_description" { default = "ops-subnet-02 primary" }
variable "subnet_02_secondary_svc_1_name" { default = "ops-subnet-02-svc-1" }
variable "subnet_02_secondary_svc_1_range" { default = "10.13.0.0/20" }
variable "subnet_02_secondary_svc_2_name" { default = "ops-subnet-02-svc-2" }
variable "subnet_02_secondary_svc_2_range" { default = "10.13.16.0/20" }
variable "subnet_02_secondary_pod_name" { default = "ops-subnet-02-pod" }
variable "subnet_02_secondary_pod_range" { default = "10.8.0.0/14" }

variable "subnet_03_name" { default = "dev1-subnet-01" }
variable "subnet_03_ip" { default = "10.20.0.0/22" }
variable "subnet_03_region" { default = "us-west1" }
variable "subnet_03_description" { default = "dev1-subnet-01 primary" }
variable "subnet_03_secondary_svc_1_name" { default = "dev1-subnet-01-svc-1" }
variable "subnet_03_secondary_svc_1_range" { default = "10.21.0.0/20" }
variable "subnet_03_secondary_svc_2_name" { default = "dev1-subnet-01-svc-2" }
variable "subnet_03_secondary_svc_2_range" { default = "10.21.16.0/20" }
variable "subnet_03_secondary_pod_name" { default = "dev1-subnet-01-pod" }
variable "subnet_03_secondary_pod_range" { default = "10.16.0.0/14" }

variable "subnet_04_name" { default = "dev2-subnet-01" }
variable "subnet_04_ip" { default = "10.28.0.0/22" }
variable "subnet_04_region" { default = "us-central1" }
variable "subnet_04_description" { default = "dev2-subnet-01 primary" }
variable "subnet_04_secondary_svc_1_name" { default = "dev2-subnet-01-svc-1" }
variable "subnet_04_secondary_svc_1_range" { default = "10.29.0.0/20" }
variable "subnet_04_secondary_svc_2_name" { default = "dev2-subnet-01-svc-2" }
variable "subnet_04_secondary_svc_2_range" { default = "10.29.16.0/20" }
variable "subnet_04_secondary_pod_name" { default = "dev2-subnet-01-pod" }
variable "subnet_04_secondary_pod_range" { default = "10.24.0.0/14" }

variable "subnet_05_name" { default = "dev3-subnet-01" }
variable "subnet_05_ip" { default = "10.36.0.0/22" }
variable "subnet_05_region" { default = "us-east1" }
variable "subnet_05_description" { default = "dev3-subnet-01 primary" }
variable "subnet_05_secondary_svc_1_name" { default = "dev3-subnet-01-svc-1" }
variable "subnet_05_secondary_svc_1_range" { default = "10.37.0.0/20" }
variable "subnet_05_secondary_svc_2_name" { default = "dev3-subnet-01-svc-2" }
variable "subnet_05_secondary_svc_2_range" { default = "10.37.16.0/20" }
variable "subnet_05_secondary_pod_name" { default = "dev3-subnet-01-pod" }
variable "subnet_05_secondary_pod_range" { default = "10.32.0.0/14" }

variable "subnet_06_name" { default = "ops-subnet-03" }
variable "subnet_06_ip" { default = "10.44.0.0/22" }
variable "subnet_06_region" { default = "us-east1" }
variable "subnet_06_description" { default = "ops-subnet-03 primary" }
variable "subnet_06_secondary_svc_1_name" { default = "ops-subnet-03-svc-1" }
variable "subnet_06_secondary_svc_1_range" { default = "10.45.0.0/20" }
variable "subnet_06_secondary_svc_2_name" { default = "ops-subnet-03-svc-2" }
variable "subnet_06_secondary_svc_2_range" { default = "10.45.16.0/20" }
variable "subnet_06_secondary_pod_name" { default = "ops-subnet-03-pod" }
variable "subnet_06_secondary_pod_range" { default = "10.40.0.0/14" }
