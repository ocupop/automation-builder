aws_region         = "us-west-2"
cluster_name       = "my-eks-cluster"
kubernetes_version = "1.28"
vpc_cidr          = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
desired_nodes     = 2
min_nodes         = 1
max_nodes         = 4
node_instance_type = "t3.medium"

# Application configuration
app_name        = "my-app"
container_image = "your-image:latest"  # Replace with your image
container_port  = 8080
service_port    = 80
service_type    = "LoadBalancer"
replicas        = 2

container_environment = [
  {
    name  = "ENVIRONMENT"
    value = "production"
  }
  # Add more environment variables as needed
]
