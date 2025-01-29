# Enable Identity Platform API
resource "google_project_service" "identity_platform" {
  project = var.project_id
  service = "identitytoolkit.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy        = false
}

# Identity Platform Config
resource "google_identity_platform_config" "flowise" {
  project = var.project_id

  # Enable email link sign-in method
  email {
    enabled           = true
    password_required = false
  }

  # Configure authorized domains
  authorized_domains = ["ocupop.com"]

  depends_on = [
    google_project_service.identity_platform
  ]
}

# Cloud Function for email domain validation
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-functions"
  location = var.region
}

resource "google_storage_bucket_object" "function_code" {
  name   = "email-validator.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.module}/functions/email-validator.zip"
}

resource "google_cloudfunctions_function" "email_validator" {
  name        = "${var.project_name}-email-validator"
  description = "Validates email domains for Flowise authentication"
  runtime     = "nodejs18"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_code.name
  trigger_http          = true
  entry_point          = "validateEmail"

  environment_variables = {
    ALLOWED_DOMAIN = "ocupop.com"
  }
}

# Firestore configuration for session management
resource "google_firestore_database" "sessions" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}

# Cloud Function for session management
resource "google_cloudfunctions_function" "session_manager" {
  name        = "${var.project_name}-session-manager"
  description = "Manages authentication sessions"
  runtime     = "nodejs18"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.session_manager_code.name
  trigger_http          = true
  entry_point          = "manageSession"

  environment_variables = {
    PROJECT_ID = var.project_id
  }
}

# Cloud Function for email sending
resource "google_cloudfunctions_function" "email_sender" {
  name        = "${var.project_name}-email-sender"
  description = "Sends magic link emails"
  runtime     = "nodejs18"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.email_sender_code.name
  trigger_http          = true
  entry_point          = "sendMagicLink"

  environment_variables = {
    PROJECT_ID      = var.project_id
    APP_NAME        = var.project_name
    SMTP_HOST       = "smtp.gmail.com"
    OCUPOP_LOGO_URL = var.ocupop_logo_url
  }
}

# Upload function code
resource "google_storage_bucket_object" "session_manager_code" {
  name   = "session-manager.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.module}/functions/session-manager.zip"
}

resource "google_storage_bucket_object" "email_sender_code" {
  name   = "email-sender.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.module}/functions/email-sender.zip"
}

# Secret Manager for SMTP credentials
resource "google_secret_manager_secret" "smtp_username" {
  secret_id = "smtp-username"
  project   = var.project_id

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "smtp_password" {
  secret_id = "smtp-password"
  project   = var.project_id

  replication {
    automatic = true
  }
}

# IAM for Cloud Functions
resource "google_cloudfunctions_function_iam_member" "session_manager_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.session_manager.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_cloudfunctions_function_iam_member" "email_sender_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.email_sender.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# Cloud Run service with Identity Platform integration
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
          name  = "FLOWISE_AUTH_ENABLED"
          value = "true"
        }

        env {
          name  = "IDENTITY_PLATFORM_API_KEY"
          value = google_identity_platform_config.flowise.api_key
        }

        env {
          name  = "ALLOWED_DOMAIN"
          value = "ocupop.com"
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
}

# IAP configuration with custom domain
resource "google_iap_web_type_compute_iam_binding" "flowise_iap_binding" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  members = [
    "domain:ocupop.com"
  ]
}

# Custom domain and SSL certificate
resource "google_compute_managed_ssl_certificate" "flowise" {
  name = "${var.project_name}-flowise-cert"

  managed {
    domains = [var.domain_name]
  }
}

# Load Balancer configuration
resource "google_compute_backend_service" "flowise" {
  name                  = "${var.project_name}-flowise-backend"
  protocol              = "HTTPS"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn           = false

  backend {
    group = google_compute_region_network_endpoint_group.flowise_neg.id
  }

  iap {
    oauth2_client_id     = google_iap_client.flowise_client.client_id
    oauth2_client_secret = google_iap_client.flowise_client.secret
  }

  security_policy = google_compute_security_policy.flowise.id
}

# Security policy to restrict access to ocupop.com domain
resource "google_compute_security_policy" "flowise" {
  name = "${var.project_name}-flowise-security-policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      expr {
        expression = "request.headers['From'].contains('ocupop.com')"
      }
    }
    description = "Allow ocupop.com domain"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny all other traffic"
  }
}

# Update variables
variable "ocupop_logo_url" {
  description = "URL for the Ocupop logo in email templates"
  type        = string
}
