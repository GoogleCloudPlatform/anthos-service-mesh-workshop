# Static IP for ingress
resource "google_compute_global_address" "ingress" {
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name    = "istio-ingressgateway"
}

# Cloud endpoints for DNS
module "cloud-ep-dns" {
  # Return to module registry after this is merged: https://github.com/terraform-google-modules/terraform-google-endpoints-dns/pull/2
  #source      = "terraform-google-modules/endpoints-dns/google"
  source      = "github.com/danisla/terraform-google-endpoints-dns?ref=0.12upgrade"
  project     = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name        = "frontend"
  external_ip = google_compute_global_address.ingress.address
}

# Managed certificate
resource "google_compute_managed_ssl_certificate" "ingress" {
  provider = google-beta
  project  = data.terraform_remote_state.ops_project.outputs.ops_project_id

  name = "istio-ingressgateway"

  managed {
    domains = ["${module.cloud-ep-dns.endpoint}."]
  }
}

# Firewall rule
resource "google_compute_firewall" "ingress-lb" {
  name    = "istio-ingressgateway-lb"
  project = data.terraform_remote_state.shared_vpc.outputs.svpc_host_project_id
  network = data.terraform_remote_state.shared_vpc.outputs.network_name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}

# Health check
resource "google_compute_health_check" "ingress" {
  project            = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name               = "istio-ingressgateway"
  check_interval_sec = 10

  tcp_health_check {
    port = "15020"
  }
}

# BackendService
resource "google_compute_backend_service" "ingress" {
  project       = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name          = "istio-ingressgateway"
  health_checks = [google_compute_health_check.ingress.self_link]
  protocol      = "HTTP"
}

# URL map - HTTPS
resource "google_compute_url_map" "ingress" {
  project         = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name            = "istio-ingressgateway"
  default_service = google_compute_backend_service.ingress.self_link
}

# Target HTTP proxy
resource "google_compute_target_http_proxy" "ingress" {
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name    = "istio-ingressgateway"
  url_map = google_compute_url_map.ingress.self_link
}

# Target HTTPS proxy
resource "google_compute_target_https_proxy" "ingress" {
  project          = data.terraform_remote_state.ops_project.outputs.ops_project_id
  name             = "istio-ingressgateway"
  url_map          = google_compute_url_map.ingress.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.ingress.self_link]
}

# Forwarding rule - HTTP
resource "google_compute_global_forwarding_rule" "ingress-http" {
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id

  name       = "istio-ingressgateway-http"
  ip_address = google_compute_global_address.ingress.address
  target     = google_compute_target_http_proxy.ingress.self_link
  port_range = "80"
}


# Forwarding rule - HTTPS
resource "google_compute_global_forwarding_rule" "ingress" {
  project = data.terraform_remote_state.ops_project.outputs.ops_project_id

  name       = "istio-ingressgateway"
  ip_address = google_compute_global_address.ingress.address
  target     = google_compute_target_https_proxy.ingress.self_link
  port_range = "443"
}
