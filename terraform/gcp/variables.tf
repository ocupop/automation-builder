variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy to"
  type        = string
  default     = "us-west1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy (e.g., 'gcr.io/project/image:tag')"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "CPU allocation for the container (e.g., '1' for 1 vCPU)"
  type        = string
  default     = "1"
}

variable "container_memory" {
  description = "Memory allocation for the container (e.g., '512Mi')"
  type        = string
  default     = "512Mi"
}

variable "container_environment" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "min_instances" {
  description = "Minimum number of instances to run"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances to run"
  type        = number
  default     = 10
}

variable "public_access" {
  description = "Whether to allow public access to the service"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Custom domain to map to the service (optional)"
  type        = string
  default     = ""
}
