# AWS EKS Deployment with Terraform

This configuration sets up a production-ready EKS (Elastic Kubernetes Service) cluster on AWS. Here are the key differences from the GKE version:

## AWS vs GKE Differences

1. **Networking**
   - AWS requires explicit NAT Gateway configuration
   - Different subnet tagging for load balancer integration
   - AWS-specific CNI (Container Network Interface)

2. **IAM Integration**
   - AWS uses IAM roles and policies
   - More explicit IAM configuration required
   - Different service account binding process

3. **Node Management**
   - AWS uses EKS managed node groups
   - Different instance type selection
   - AWS-specific auto-scaling configuration

## Setup Instructions

1. **Prerequisites**
   ```bash
   # Install AWS CLI
   brew install awscli

   # Install kubectl
   brew install kubernetes-cli

   # Install AWS IAM Authenticator
   brew install aws-iam-authenticator
   ```

2. **Configure AWS Credentials**
   ```bash
   aws configure
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Configure Variables**
   Edit `terraform.tfvars`:
   ```hcl
   aws_region         = "your-region"
   cluster_name       = "your-cluster-name"
   container_image    = "your-image:tag"
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

6. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name your-cluster-name --region your-region
   ```

## Infrastructure Components

1. **VPC Configuration**
   - Custom VPC with public and private subnets
   - NAT Gateways for private subnet connectivity
   - Internet Gateway for public access
   - Proper subnet tagging for EKS integration

2. **EKS Cluster**
   - Managed Kubernetes control plane
   - AWS IAM integration
   - Private API endpoint option
   - Kubernetes version management

3. **Node Groups**
   - Managed node groups
   - Auto-scaling configuration
   - Instance type selection
   - Kubernetes labels and taints

4. **Security**
   - IAM roles and policies
   - Security groups
   - Network policies
   - Pod security policies

## AWS-Specific Features

1. **AWS Load Balancer Controller**
   ```bash
   # Install AWS Load Balancer Controller
   helm repo add eks https://aws.github.io/eks-charts
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     --namespace kube-system \
     --set clusterName=your-cluster-name
   ```

2. **AWS Container Insights**
   ```bash
   # Enable Container Insights
   kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest.yaml
   ```

## Cost Optimization

1. **EC2 Instance Selection**
   - Use Spot Instances for non-critical workloads
   - Right-size node instances
   - Utilize auto-scaling effectively

2. **Network Costs**
   - Use private endpoints where possible
   - Consider Direct Connect for high bandwidth needs
   - Monitor NAT Gateway usage

## Monitoring and Logging

1. **CloudWatch Integration**
   - Container Insights
   - CloudWatch Logs
   - Custom metrics
   - Alarms and dashboards

2. **X-Ray Tracing**
   ```bash
   # Enable X-Ray
   kubectl apply -f https://aws-otel-eks-charts.s3.amazonaws.com/aws-otel-collector.yaml
   ```

## Security Best Practices

1. **Network Security**
   - Use private endpoints
   - Implement security groups
   - Enable VPC flow logs
   - Use AWS WAF with ALB

2. **IAM Security**
   - Use IRSA (IAM Roles for Service Accounts)
   - Implement least privilege
   - Regular credential rotation
   - Enable AWS Organizations

## Common Issues and Solutions

1. **Authentication Issues**
   ```bash
   # Verify AWS IAM Authenticator
   aws-iam-authenticator verify

   # Check IAM roles
   aws iam get-role --role-name your-role-name
   ```

2. **Networking Issues**
   ```bash
   # Check VPC CNI
   kubectl describe daemonset aws-node -n kube-system

   # Verify subnet tags
   aws ec2 describe-subnets --filters Name=tag:kubernetes.io/cluster/your-cluster-name,Values=shared
   ```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

⚠️ Warning: This will remove all resources including the EKS cluster and any deployed applications.

## Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [EKS Workshop](https://www.eksworkshop.com/)
- [AWS Container Blog](https://aws.amazon.com/blogs/containers/)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
