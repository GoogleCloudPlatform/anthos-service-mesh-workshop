locals {
  # Download istio operator, copy to GCS
  # This will be added to the cloudbuild repo for the project.
  istio_operator_download_script = <<EOT
wget -qO- https://github.com/istio/operator/archive/${var.istio_version}.tar.gz | tar -zxf - operator-${var.istio_version}/deploy
gsutil -m rsync -r -d operator-${var.istio_version}/deploy gs://${var.tfadmin_proj}/ops/istio-operator-${var.istio_version}

wget -qO- --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  https://us-central1-cnrm-eap.cloudfunctions.net/download/latest/infra/install-bundle-with-workload-identity.tar.gz | tar -zxvf - 
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