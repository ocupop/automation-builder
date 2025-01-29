project_name    = "my-container-app"
aws_region     = "us-west-2"
container_name = "my-app"
container_image = "your-docker-image:latest"  # Replace with your Docker image
container_port = 80
container_cpu  = 256
container_memory = 512
service_desired_count = 1

container_environment = [
  {
    name  = "ENVIRONMENT"
    value = "production"
  }
  # Add more environment variables as needed
]
