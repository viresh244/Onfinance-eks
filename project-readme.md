# OnFinance AI - EKS Implementation

This repository contains the implementation of a full-stack application on AWS EKS, with a focus on logging, monitoring, and scalability. The solution follows best practices for high availability and security.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Components](#components)
- [Setup Instructions](#setup-instructions)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Application Deployment](#application-deployment)
- [Monitoring and Logging](#monitoring-and-logging)
- [Data Integration](#data-integration)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security Considerations](#security-considerations)
- [Cleanup](#cleanup)

## Architecture Overview

The architecture is designed to be highly available, scalable, and secure:

- **Multi-AZ Deployment**: Resources are distributed across multiple Availability Zones for fault tolerance.
- **Auto-scaling**: Auto-scaling groups for EKS worker nodes and Horizontal Pod Autoscaler for Kubernetes pods.
- **Networking**: VPC with public and private subnets, NAT Gateways for outbound traffic.
- **Security**: IAM roles with least privilege, Network security groups, Kubernetes RBAC.
- **Monitoring**: CloudWatch Metrics and Logs, Custom Dashboards and Alarms.
- **CI/CD**: Automated deployment pipeline using GitHub Actions.

## Components

### AWS Services Used

- **Amazon EKS**: Managed Kubernetes service for containerized applications
- **Amazon ECR**: Container registry for docker images
- **Amazon VPC**: Network isolation and security
- **Amazon RDS**: Managed relational database service
- **Amazon DynamoDB**: NoSQL database for the data integration pipeline
- **Amazon S3**: Object storage for data and logs
- **Amazon CloudWatch**: Monitoring and logging solution
- **AWS IAM**: Identity and access management
- **AWS Secrets Manager**: Secure storage for sensitive information
- **Amazon SNS**: Notification service for alerts

### Application Components

- **Backend API**: REST API service deployed as Kubernetes pods
- **Frontend Web**: Web interface deployed as Kubernetes pods
- **Data Integration**: Lambda function fetching stock data from external APIs

## Setup Instructions

### Prerequisites

1. AWS CLI (configured with appropriate credentials)
2. Terraform (version 1.2.5 or later)
3. kubectl
4. Docker

### Environment Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/onfinance-eks.git
   cd onfinance-eks
   ```

2. Set up environment variables (or use Terraform variables):
   ```
   export AWS_REGION=us-east-1
   export PROJECT_NAME=onfinance
   export ENVIRONMENT=production
   ```

## Infrastructure Deployment

### Using Terraform

1. Initialize Terraform:
   ```
   cd terraform
   terraform init
   ```

2. Review the execution plan:
   ```
   terraform plan -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT"
   ```

3. Apply the configuration:
   ```
   terraform apply -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT"
   ```

4. After successful deployment, update your kubeconfig:
   ```
   aws eks update-kubeconfig --name <cluster-name> --region <region>
   ```

## Application Deployment

### Kubernetes Deployment

1. Navigate to the Kubernetes manifests directory:
   ```
   cd kubernetes
   ```

2. Create the namespace:
   ```
   kubectl create namespace onfinance
   ```

3. Apply the Kubernetes manifests:
   ```
   kubectl apply -f .
   ```

4. Verify the deployments:
   ```
   kubectl get deployments -n onfinance
   kubectl get pods -n onfinance
   kubectl get services -n onfinance
   ```

## Monitoring and Logging

### CloudWatch Integration

The solution includes CloudWatch integration for logs and metrics:

1. **Container Insights**: Provides metrics for the EKS cluster.
2. **Fluent Bit**: Collects and forwards container logs to CloudWatch Logs.
3. **CloudWatch Dashboards**: Custom dashboards for monitoring the infrastructure.
4. **CloudWatch Alarms**: Alerts for critical metrics.

### Accessing Logs

```
aws logs get-log-events --log-group-name /aws/eks/<cluster-name>/cluster --log-stream-name <log-stream-name>
```

### Viewing Dashboards

Access CloudWatch dashboards through the AWS Management Console:
1. Go to CloudWatch service
2. Select Dashboards
3. Open the "onfinance-eks-dashboard"

## Data Integration

The data integration pipeline fetches stock data from a public API and stores it in S3 and DynamoDB.

### Triggering the Pipeline Manually

```
aws lambda invoke --function-name <project-name>-stock-data-integration --payload '{}' response.json
```

### Viewing the Data

Stock data is stored in:
1. **S3 Bucket**: `<project-name>-stock-data-<environment>`
2. **DynamoDB Table**: `<project-name>-stock-data-<environment>`

## CI/CD Pipeline

The project includes a GitHub Actions workflow for continuous integration and deployment:

1. **Lint and Test**: Validates code quality
2. **Terraform Plan**: Plans infrastructure changes
3. **Build and Push**: Builds Docker images and pushes to ECR
4. **Deploy**: Applies Terraform plan and deploys to EKS

### Setting Up GitHub Secrets

The following secrets need to be configured in your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Security Considerations

- IAM roles follow the principle of least privilege
- Network security using VPC, subnets, and security groups
- Secrets managed through AWS Secrets Manager
- HTTPS for all external endpoints
- Container security best practices

## Cleanup

To avoid incurring charges, clean up the resources when they're no longer needed:

1. Delete Kubernetes resources:
   ```
   kubectl delete namespace onfinance
   ```

2. Destroy Terraform resources:
   ```
   cd terraform
   terraform destroy -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT"
   ```

3. Confirm deletion of all resources through the AWS Management Console
