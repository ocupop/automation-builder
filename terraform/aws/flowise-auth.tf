# Cognito User Pool for Flowise Authentication
resource "aws_cognito_user_pool" "flowise" {
  name = "${var.project_name}-flowise-users"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

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
}

# Cognito App Client
resource "aws_cognito_user_pool_client" "flowise_client" {
  name         = "${var.project_name}-flowise-client"
  user_pool_id = aws_cognito_user_pool.flowise.id

  generate_secret = true
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = ["https://${aws_lb.flowise.dns_name}/oauth2/callback"]
  logout_urls   = ["https://${aws_lb.flowise.dns_name}"]
}

# ALB for Flowise with authentication
resource "aws_lb" "flowise" {
  name               = "${var.project_name}-flowise-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.flowise_lb.id]
  subnets           = aws_subnet.public[*].id
}

# ALB Listener with HTTPS
resource "aws_lb_listener" "flowise_https" {
  load_balancer_arn = aws_lb.flowise.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.flowise.arn
      user_pool_client_id = aws_cognito_user_pool_client.flowise_client.id
      user_pool_domain    = aws_cognito_user_pool_domain.flowise.domain
    }

    type             = "forward"
    target_group_arn = aws_lb_target_group.flowise.arn
  }
}

# ALB Target Group
resource "aws_lb_target_group" "flowise" {
  name        = "${var.project_name}-flowise-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# Security Group for ALB
resource "aws_security_group" "flowise_lb" {
  name        = "${var.project_name}-flowise-lb-sg"
  description = "Security group for Flowise ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Cognito Domain
resource "aws_cognito_user_pool_domain" "flowise" {
  domain       = "${var.project_name}-flowise"
  user_pool_id = aws_cognito_user_pool.flowise.id
}

# Additional variables for Flowise container
locals {
  flowise_environment = concat(var.container_environment, [
    {
      name  = "FLOWISE_USERNAME"
      value = var.flowise_admin_username
    },
    {
      name  = "FLOWISE_PASSWORD"
      value = var.flowise_admin_password
    },
    {
      name  = "FLOWISE_AUTH_ENABLED"
      value = "true"
    }
  ])
}
