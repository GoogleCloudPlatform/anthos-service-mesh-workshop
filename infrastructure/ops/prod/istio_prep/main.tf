locals {
  # Download istio operator, copy to GCS
  # This will be added to the cloudbuild repo for the project.
  istio_operator_download_script = <<EOT
wget -qO- https://github.com/istio/operator/archive/${var.istio_version}.tar.gz | tar -zxf - operator-${var.istio_version}/deploy
kubectl kustomize operator-${var.istio_version}/deploy > istio-operator-${var.istio_version}.yaml
gsutil -m cp istio-operator-${var.istio_version}.yaml gs://${var.tfadmin_proj}/ops/istio-operator-${var.istio_version}.yaml
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