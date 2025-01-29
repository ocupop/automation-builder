# Cognito User Pool with passwordless configuration
resource "aws_cognito_user_pool" "flowise" {
  name = "${var.project_name}-flowise-users"

  # Email configuration
  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = "noreply@ocupop.com"
    source_arn           = aws_ses_email_identity.sender.arn
  }

  # Passwordless authentication settings
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
  
  # Only allow ocupop.com email addresses
  schema {
    name                = "email"
    attribute_data_type = "String"
    required           = true
    mutable            = true
    string_attribute_constraints {
      min_length = 3
      max_length = 255
    }
  }

  # Custom lambda trigger to validate email domain
  lambda_config {
    pre_sign_up = aws_lambda_function.email_domain_validator.arn
    custom_message = aws_lambda_function.custom_verification_message.arn
    pre_token_generation = aws_lambda_function.session_manager.arn
  }

  # Password policy (for admin created users)
  password_policy {
    minimum_length    = 16
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # User account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

# Lambda function for email domain validation
resource "aws_lambda_function" "email_domain_validator" {
  filename         = "${path.module}/lambda/email-validator.zip"
  function_name    = "${var.project_name}-email-validator"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"

  environment {
    variables = {
      ALLOWED_DOMAIN = "ocupop.com"
    }
  }
}

# Lambda function for custom verification message
resource "aws_lambda_function" "custom_verification_message" {
  filename         = "${path.module}/lambda/verification-message.zip"
  function_name    = "${var.project_name}-verification-message"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"

  environment {
    variables = {
      APP_NAME = var.project_name
    }
  }
}

# Lambda function for session management
resource "aws_lambda_function" "session_manager" {
  filename         = "${path.module}/lambda/session-manager.zip"
  function_name    = "${var.project_name}-session-manager"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"

  environment {
    variables = {
      SESSION_TABLE_NAME = aws_dynamodb_table.sessions.name
    }
  }
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Add DynamoDB permissions to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# DynamoDB table for session management
resource "aws_dynamodb_table" "sessions" {
  name           = "${var.project_name}-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "sessionId"
  
  attribute {
    name = "sessionId"
    type = "S"
  }
  
  ttl {
    attribute_name = "expirationTime"
    enabled        = true
  }
  
  tags = {
    Name = "${var.project_name}-sessions"
  }
}

# Lambda permission for Cognito
resource "aws_lambda_permission" "cognito_email_validator" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_domain_validator.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.flowise.arn
}

# Lambda permission for session management
resource "aws_lambda_permission" "cognito_session_manager" {
  statement_id  = "AllowCognitoInvokeSessionManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.session_manager.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.flowise.arn
}

# Cognito App Client with passwordless flow
resource "aws_cognito_user_pool_client" "flowise_client" {
  name         = "${var.project_name}-flowise-client"
  user_pool_id = aws_cognito_user_pool.flowise.id

  generate_secret = true
  
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = ["https://${aws_lb.flowise.dns_name}/oauth2/callback"]
  logout_urls   = ["https://${aws_lb.flowise.dns_name}"]
  
  prevent_user_existence_errors = "ENABLED"
}

# SES email identity for sending custom emails
resource "aws_ses_email_identity" "sender" {
  email = "noreply@ocupop.com"
}
