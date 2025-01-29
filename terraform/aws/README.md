# AWS Container Deployment with Terraform

This Terraform configuration deploys Docker containers to AWS ECS (Elastic Container Service) using Fargate. The infrastructure includes a VPC, ECS cluster, task definitions, and all necessary networking components.

## Prerequisites

- [Terraform](https://www.terraform.io/) (>= 1.5.0)
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- Docker image pushed to a container registry (ECR, Docker Hub, etc.)
- AWS credentials with appropriate permissions

## Configuration Files

- `main.tf`: Main infrastructure configuration
- `variables.tf`: Variable definitions
- `terraform.tfvars`: Variable values (needs to be customized)

## Setup Instructions

1. **Configure AWS Credentials**

   Either set environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```
   
   Or configure AWS CLI:
   ```bash
   aws configure
   ```

2. **Customize Configuration**

   Edit `terraform.tfvars` with your specific values:
   ```hcl
   project_name    = "your-project-name"
   aws_region     = "your-preferred-region"  # e.g., us-west-2
   container_name = "your-container-name"
   container_image = "your-image:tag"        # e.g., "nginx:latest" or your ECR image
   container_port = 80                       # Port your container exposes
   container_cpu  = 256                      # CPU units (1024 = 1 vCPU)
   container_memory = 512                    # Memory in MiB
   service_desired_count = 1                 # Number of container instances
   
   container_environment = [
     {
       name  = "ENV_VAR_NAME"
       value = "env_var_value"
     }
   ]
   ```

3. **Initialize Terraform**

   ```bash
   terraform init
   ```

4. **Review the Plan**

   ```bash
   terraform plan
   ```

   This will show you all resources that will be created.

5. **Apply the Configuration**

   ```bash
   terraform apply
   ```

   Type `yes` when prompted to create the resources.

## Infrastructure Components

This configuration creates:

- VPC with public subnets across 2 availability zones
- ECS Cluster using Fargate (serverless)
- ECS Task Definition for your container
- ECS Service to maintain desired container count
- Security Groups for network access
- IAM roles and policies for ECS tasks
- CloudWatch Log Group for container logs

## Monitoring

- View container logs in CloudWatch Logs under `/ecs/[project-name]`
- Monitor ECS service status in AWS Console
- Check container health in ECS task details

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

⚠️ Warning: This will remove all resources created by this Terraform configuration.

## Cost Considerations

The main cost components are:

- Fargate task runtime
- Data transfer
- CloudWatch Logs storage

Use AWS Cost Explorer to monitor expenses.

## Security Notes

- The configuration creates a public subnet for simplicity
- Security group allows inbound traffic on the container port
- Consider adding:
  - Private subnets
  - VPC endpoints
  - More restrictive security groups
  - AWS WAF for web applications

## Troubleshooting

1. **Container Not Starting**
   - Check ECS task logs in CloudWatch
   - Verify container image exists and is accessible
   - Check CPU/memory allocation is sufficient

2. **Network Issues**
   - Verify security group rules
   - Check VPC and subnet configuration
   - Ensure container port matches service configuration

3. **Permission Issues**
   - Verify AWS credentials have required permissions
   - Check ECS task execution role permissions
   - Ensure container registry access

## Support

For issues or questions:
1. Check AWS ECS documentation
2. Review Terraform AWS provider documentation
3. Consult AWS support if needed
