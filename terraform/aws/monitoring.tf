# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "auth_logs" {
  name              = "/aws/cognito/${var.project_name}/auth"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = toset([
    "email-validator",
    "verification-message",
    "session-manager",
    "rate-limiter"
  ])
  
  name              = "/aws/lambda/${var.project_name}-${each.key}"
  retention_in_days = 30
}

# CloudWatch Metrics and Alarms
resource "aws_cloudwatch_metric_alarm" "auth_failures" {
  alarm_name          = "${var.project_name}-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "AuthenticationFailures"
  namespace           = "AWS/Cognito"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "Authentication failures exceeded threshold"
  alarm_actions      = [aws_sns_topic.auth_alerts.arn]

  dimensions = {
    UserPoolId = aws_cognito_user_pool.flowise.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rate_limit_exceeded" {
  alarm_name          = "${var.project_name}-rate-limit-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RateLimitExceeded"
  namespace           = "Custom/Auth"
  period             = "300"
  statistic          = "Sum"
  threshold          = "5"
  alarm_description  = "Rate limit exceeded threshold"
  alarm_actions      = [aws_sns_topic.auth_alerts.arn]
}

# SNS Topic for Alerts
resource "aws_sns_topic" "auth_alerts" {
  name = "${var.project_name}-auth-alerts"
}

resource "aws_sns_topic_subscription" "auth_alerts_email" {
  topic_arn = aws_sns_topic.auth_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "auth_dashboard" {
  dashboard_name = "${var.project_name}-auth-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Cognito", "SignInSuccesses", "UserPoolId", aws_cognito_user_pool.flowise.id],
            [".", "SignInFailures", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Authentication Attempts"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Custom/Auth", "RateLimitExceeded", "Service", "Authentication"],
            [".", "RateLimitWarning", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Rate Limiting"
        }
      }
    ]
  })
}
