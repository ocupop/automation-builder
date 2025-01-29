# GCP Container Deployment with Terraform

This Terraform configuration deploys Docker containers to Google Cloud Run, a fully managed serverless platform. The infrastructure includes VPC networking, service accounts, and all necessary components for running containerized applications.

## Prerequisites

- [Terraform](https://www.terraform.io/) (>= 1.5.0)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- Docker image pushed to Google Container Registry (GCR) or Artifact Registry
- GCP project with billing enabled
- GCP credentials configured

## Configuration Files

- `main.tf`: Main infrastructure configuration
- `variables.tf`: Variable definitions
- `terraform.tfvars`: Variable values (needs to be customized)

## Setup Instructions

1. **Configure GCP Authentication**

   Option 1: Set up application-default credentials:
   ```bash
   gcloud auth application-default login
   ```
   
   Option 2: Use a service account key:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
   ```

2. **Enable Required APIs**

   The Terraform configuration will automatically enable:
   - Cloud Run API
   - Container Registry API
   - Cloud Build API

3. **Customize Configuration**

   Edit `terraform.tfvars` with your specific values:
   ```hcl
   project_id     = "your-gcp-project-id"
   project_name   = "your-project-name"
   region         = "your-preferred-region"  # e.g., us-west1
   service_name   = "your-service-name"
   container_image = "gcr.io/your-project/image:tag"
   container_port = 8080
   container_cpu  = "1"
   container_memory = "512Mi"
   min_instances  = 0
   max_instances  = 10
   public_access  = true
   
   container_environment = [
     {
       name  = "ENV_VAR_NAME"
       value = "env_var_value"
     }
   ]
   ```

4. **Initialize Terraform**

   ```bash
   terraform init
   ```

5. **Review the Plan**

   ```bash
   terraform plan
   ```

6. **Apply the Configuration**

   ```bash
   terraform apply
   ```

## Infrastructure Components

This configuration creates:

- Cloud Run service with specified container
- VPC network and subnet
- VPC Access Connector
- IAM roles and permissions
- Domain mapping (optional)
- Auto-scaling configuration

## Features

- **Serverless**: No infrastructure management required
- **Auto-scaling**: Scales from zero to many instances
- **VPC Integration**: Secure network access
- **Custom Domains**: Optional domain mapping
- **HTTPS**: Automatic SSL/TLS certificates
- **IAM Integration**: Fine-grained access control

## Monitoring

- View container logs in Cloud Logging
- Monitor service metrics in Cloud Monitoring
- Track request latency and error rates
- View auto-scaling metrics

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

⚠️ Warning: This will remove all resources created by this Terraform configuration.

## Cost Considerations

Cloud Run pricing is based on:
- Request count
- Resource allocation (CPU/memory)
- Network egress
- Idle time (if min instances > 0)

## Security Notes

- HTTPS is enabled by default
- IAM controls access to the service
- VPC provides network isolation
- Consider:
  - Identity-Aware Proxy (IAP)
  - VPC Service Controls
  - Cloud Armor for DDoS protection

## Troubleshooting

1. **Container Issues**
   - Check Cloud Run revision logs
   - Verify container image exists in GCR
   - Check resource allocation

2. **Network Problems**
   - Verify VPC connector configuration
   - Check firewall rules
   - Validate egress settings

3. **Permission Issues**
   - Check IAM roles
   - Verify service account permissions
   - Review Cloud Run invoker settings

## Support

For issues or questions:
1. Check [Cloud Run documentation](https://cloud.google.com/run/docs)
2. Review [Terraform GCP provider documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
3. Consult Google Cloud support
