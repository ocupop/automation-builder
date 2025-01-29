# Enable required APIs
resource "google_project_service" "auth_apis" {
  for_each = toset([
    "iap.googleapis.com",
    "cloudidentity.googleapis.com"
  ])
  
  project = var.project_id
  service = each.key

  disable_dependent_services = true
  disable_on_destroy        = false
}

# OAuth brand for IAP
resource "google_iap_brand" "flowise_brand" {
  support_email     = var.support_email
  application_title = "${var.project_name}-flowise"
  project          = var.project_number

  depends_on = [
    google_project_service.auth_apis
  ]
}

# OAuth client for IAP
resource "google_iap_client" "flowise_client" {
  display_name = "${var.project_name}-flowise-client"
  brand        = google_iap_brand.flowise_brand.name
}

# IAP settings for Cloud Run
resource "google_iap_web_iam_member" "flowise_iap_member" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "user:${var.admin_email}"
}

# Cloud Run service with IAP
resource "google_cloud_run_service" "flowise" {
  name     = "${var.project_name}-flowise"
  location = var.region

  template {
    spec {
      containers {
        image = var.flowise_image

        resources {
          limits = {
            cpu    = var.container_cpu
            memory = var.container_memory
          }
        }

        env {
          name  = "FLOWISE_USERNAME"
          value = var.flowise_admin_username
        }
        env {
          name  = "FLOWISE_PASSWORD"
          value = var.flowise_admin_password
        }
        env {
          name  = "FLOWISE_AUTH_ENABLED"
          value = "true"
        }

        dynamic "env" {
          for_each = var.container_environment
          content {
            name  = env.value.name
            value = env.value.value
          }
        }

        ports {
          container_port = 3000
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.auth_apis
  ]
}

# IAP configuration for Cloud Run
resource "google_iap_web_type_compute_iam_binding" "flowise_iap_binding" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  members = [
    "user:${var.admin_email}",
  ]
}

# Load Balancer for Cloud Run with IAP
resource "google_compute_global_address" "flowise_lb_ip" {
  name = "${var.project_name}-flowise-ip"
}

resource "google_compute_managed_ssl_certificate" "flowise" {
  name = "${var.project_name}-flowise-cert"

  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_backend_service" "flowise" {
  name                  = "${var.project_name}-flowise-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn           = false
  custom_request_headers = ["Host: ${google_cloud_run_service.flowise.status[0].url}"]

  backend {
    group = google_compute_region_network_endpoint_group.flowise_neg.id
  }

  iap {
    oauth2_client_id     = google_iap_client.flowise_client.client_id
    oauth2_client_secret = google_iap_client.flowise_client.secret
  }
}

resource "google_compute_url_map" "flowise" {
  name            = "${var.project_name}-flowise-urlmap"
  default_service = google_compute_backend_service.flowise.id
}

resource "google_compute_target_https_proxy" "flowise" {
  name             = "${var.project_name}-flowise-https-proxy"
  url_map          = google_compute_url_map.flowise.id
  ssl_certificates = [google_compute_managed_ssl_certificate.flowise.id]
}

resource "google_compute_global_forwarding_rule" "flowise" {
  name       = "${var.project_name}-flowise-lb"
  target     = google_compute_target_https_proxy.flowise.id
  port_range = "443"
  ip_address = google_compute_global_address.flowise_lb_ip.address
}

resource "google_compute_region_network_endpoint_group" "flowise_neg" {
  name                  = "${var.project_name}-flowise-neg"
  network_endpoint_type = "SERVERLESS"
  region               = var.region
  cloud_run {
    service = google_cloud_run_service.flowise.name
  }
}
