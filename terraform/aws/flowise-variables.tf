variable "flowise_admin_username" {
  description = "Admin username for Flowise"
  type        = string
}

variable "flowise_admin_password" {
  description = "Admin password for Flowise"
  type        = string
  sensitive   = true
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the Flowise application"
  type        = string
}
