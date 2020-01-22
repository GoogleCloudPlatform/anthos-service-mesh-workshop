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

locals {
  # Download istio operator, copy to GCS
  # This will be added to the cloudbuild repo for the project.
  istio_operator_download_script = <<EOT
wget -qO- https://github.com/istio/operator/archive/${var.istio_version}.tar.gz | tar -zxf - operator-${var.istio_version}/deploy
gsutil -m rsync -r -d operator-${var.istio_version}/deploy gs://${var.tfadmin_proj}/ops/istio-operator-${var.istio_version}

wget -qO- https://storage.googleapis.com/asm-workshop/install-bundle-with-workload-identity.tar.gz | tar -zxvf - 
gsutil -m rsync -r -d install-bundle gs://${var.tfadmin_proj}/ops/cnrm/install-bundle
  EOT

  # Create certs - This script creates a new certs folder in the current folder and creates the fout required certs for Istio multicluster setup
  make_certs_script = <<EOT
./makecerts.sh
gsutil -m cp -r istiocerts gs://${var.tfadmin_proj}/ops/
  EOT
}

resource "null_resource" "exec_download_istio_operator" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = local.istio_operator_download_script
  }

  triggers = {
    script = local.istio_operator_download_script
  }
}

resource "null_resource" "exec_make_certs" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = local.make_certs_script
  }

  triggers = {
    script = local.make_certs_script
  }
}
