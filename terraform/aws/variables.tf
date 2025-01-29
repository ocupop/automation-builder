variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-west-2"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy (e.g., 'nginx:latest')"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "CPU units to allocate to the container (1 vCPU = 1024)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory to allocate to the container (in MiB)"
  type        = number
  default     = 512
}

variable "container_environment" {
  description = "Environment variables for the container"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "service_desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 1
}

data "aws_availability_zones" "available" {
  state = "available"
}
