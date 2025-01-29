variable "flowise_admin_username" {
  description = "Admin username for Flowise"
  type        = string
}

variable "flowise_admin_password" {
  description = "Admin password for Flowise"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the Flowise application"
  type        = string
}

variable "support_email" {
  description = "Support email for IAP OAuth brand"
  type        = string
}

variable "admin_email" {
  description = "Admin email for IAP access"
  type        = string
}

variable "project_number" {
  description = "GCP project number"
  type        = string
}

variable "flowise_image" {
  description = "Docker image for Flowise"
  type        = string
  default     = "flowiseai/flowise:latest"
}
