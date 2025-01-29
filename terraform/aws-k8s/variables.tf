variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_nodes" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
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
  default     = 2
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
