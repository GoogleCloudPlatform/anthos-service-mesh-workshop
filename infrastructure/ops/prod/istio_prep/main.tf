# Download istio
resource "null_resource" "exec_download_istio" {
  provisioner "local-exec" {
    command = <<EOT
    wget -O istio-"${var.istio_version}"-linux.tar.gz https://github.com/istio/istio/releases/download/"${var.istio_version}"/istio-"${var.istio_version}"-linux.tar.gz
    tar -xf istio-"${var.istio_version}"-linux.tar.gz -C ./
    rm -r istio-"${var.istio_version}"-linux.tar.gz
    gsutil -m cp -r istio-"${var.istio_version}" gs://"${var.tfadmin_proj}"/ops/ 
    EOT
  }
}

# Create certs - This script creates a new certs folder in the current folder and creates the fout required certs for Istio multicluster setup
resource "null_resource" "exec_make_certs" {
  provisioner "local-exec" {
    command = <<EOT
    ./makecerts.sh
    gsutil -m cp -r istiocerts gs://"${var.tfadmin_proj}"/ops/
    EOT
  }
}