project_id     = "your-project-id"
project_name   = "my-container-app"
region         = "us-west1"
service_name   = "my-service"
container_image = "gcr.io/your-project/your-image:latest"  # Replace with your image
container_port = 8080
container_cpu  = "1"
container_memory = "512Mi"
min_instances  = 0
max_instances  = 10
public_access  = true
custom_domain  = ""  # Optional: "your-domain.com"

container_environment = [
  {
    name  = "ENVIRONMENT"
    value = "production"
  }
  # Add more environment variables as needed
]
