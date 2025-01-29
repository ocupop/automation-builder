# Enable monitoring APIs
resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
}

# Log sinks for auth events
resource "google_logging_project_sink" "auth_logs" {
  name        = "${var.project_name}-auth-logs"
  destination = "storage.googleapis.com/${google_storage_bucket.auth_logs.name}"
  filter      = "resource.type=\"cloud_function\" AND (resource.labels.function_name=\"${var.project_name}-email-validator\" OR resource.labels.function_name=\"${var.project_name}-session-manager\" OR resource.labels.function_name=\"${var.project_name}-rate-limiter\")"

  unique_writer_identity = true
}

# Storage bucket for auth logs
resource "google_storage_bucket" "auth_logs" {
  name          = "${var.project_id}-auth-logs"
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Monitoring notification channel
resource "google_monitoring_notification_channel" "email" {
  display_name = "Auth Monitoring Email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

# Monitoring alert policies
resource "google_monitoring_alert_policy" "auth_failures" {
  display_name = "Authentication Failures Alert"
  combiner     = "OR"
  conditions {
    display_name = "High Auth Failure Rate"
    condition_threshold {
      filter          = "metric.type=\"custom.googleapis.com/auth/failures\" AND resource.type=\"cloud_function\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

resource "google_monitoring_alert_policy" "rate_limit" {
  display_name = "Rate Limit Exceeded Alert"
  combiner     = "OR"
  conditions {
    display_name = "Rate Limit Exceeded"
    condition_threshold {
      filter          = "metric.type=\"custom.googleapis.com/auth/rate_limit_exceeded\" AND resource.type=\"cloud_function\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Dashboard
resource "google_monitoring_dashboard" "auth" {
  dashboard_json = jsonencode({
    displayName = "Authentication Monitoring"
    gridLayout = {
      widgets = [
        {
          title = "Authentication Attempts"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"custom.googleapis.com/auth/successes\" AND resource.type=\"cloud_function\""
                  }
                  unitOverride = "1"
                }
              },
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"custom.googleapis.com/auth/failures\" AND resource.type=\"cloud_function\""
                  }
                  unitOverride = "1"
                }
              }
            ]
          }
        },
        {
          title = "Rate Limiting"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"custom.googleapis.com/auth/rate_limit_exceeded\" AND resource.type=\"cloud_function\""
                  }
                  unitOverride = "1"
                }
              }
            ]
          }
        }
      ]
    }
  })
}
