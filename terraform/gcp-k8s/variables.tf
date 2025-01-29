variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy to"
  type        = string
  default     = "us-west1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 100
}

# Application variables
variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "service_port" {
  description = "Port exposed by the Kubernetes service"
  type        = number
  default     = 80
}

variable "service_type" {
  description = "Type of Kubernetes service (LoadBalancer, ClusterIP, NodePort)"
  type        = string
  default     = "LoadBalancer"
}

variable "replicas" {
  description = "Number of container replicas to run"
  type        = number
  default     = 3
}

variable "container_cpu" {
  description = "CPU limit for the container"
  type        = string
  default     = "1"
}

variable "container_memory" {
  description = "Memory limit for the container"
  type        = string
  default     = "1Gi"
}

variable "container_cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "500m"
}

variable "container_memory_request" {
  description = "Memory request for the container"
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
