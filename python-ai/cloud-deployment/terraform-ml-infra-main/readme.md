# 🏗️ Terraform for ML Infrastructure — Infrastructure as Code for AI Workloads

## What is Terraform?
Terraform is an open-source Infrastructure as Code (IaC) tool by HashiCorp that lets you define
cloud resources in declarative HCL configuration files. For ML teams, it removes manual console
clicks by codifying GPU instances, S3 buckets, SageMaker endpoints, and VPCs into version-controlled
config that can be reproduced across dev, staging, and prod environments.

## Why Learn It?
- Reproduce ML environments consistently — no more "works on my cloud account" problems
- Manage GPU instance provisioning, auto-scaling inference fleets, and S3 model stores as code
- Separate dev/staging/prod safely using Terraform workspaces
- Understand Terraform vs Pulumi vs CDK trade-offs for ML platform decisions
- Remote state in S3 enables team collaboration without state file conflicts

## Key Concepts
```hcl
# provider.tf — AWS provider
provider "aws" {
  region = var.aws_region
}

# variables.tf
variable "aws_region"     { default = "us-east-1" }
variable "instance_type"  { default = "ml.g4dn.xlarge" }
variable "environment"    { default = "dev" }

# main.tf — SageMaker real-time endpoint
resource "aws_sagemaker_endpoint_configuration" "ml_config" {
  name = "${var.environment}-ml-endpoint-config"
  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.my_model.name
    instance_type          = var.instance_type
    initial_instance_count = 1
  }
}

resource "aws_sagemaker_endpoint" "ml_endpoint" {
  name                 = "${var.environment}-ml-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.ml_config.name
}

resource "aws_s3_bucket" "model_artifacts" {
  bucket = "${var.environment}-ml-model-artifacts"
}

# outputs.tf
output "endpoint_name" {
  value = aws_sagemaker_endpoint.ml_endpoint.name
}

# backend.tf — remote state in S3 (prevents team conflicts)
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "ml-infra/terraform.tfstate"
    region = "us-east-1"
  }
}

# modules/gpu_instance/main.tf — reusable GPU EC2 module
resource "aws_instance" "gpu" {
  ami           = var.ami_id
  instance_type = "p3.2xlarge"
  tags          = { Environment = var.environment, Purpose = "ml-training" }
}
```

## Learning Path
1. Install Terraform CLI + configure AWS credentials (`aws configure`)
2. Run `terraform init` → `terraform plan` → `terraform apply` → `terraform destroy`
3. Write a simple EC2 + S3 config; understand state file (`terraform.tfstate`)
4. Use `terraform workspace new staging` for environment separation
5. Refactor into reusable modules (`modules/sagemaker_endpoint/`)
6. Set up remote state backend in S3 + DynamoDB locking
7. Provision a SageMaker endpoint end-to-end with variables and outputs
8. Compare Terraform vs Pulumi (Python SDK) vs AWS CDK for ML use cases

## What to Build
- [ ] Terraform config that provisions an S3 bucket + IAM role for ML model storage
- [ ] SageMaker endpoint module with dev/staging/prod workspace separation
- [ ] Auto-scaling policy for a SageMaker endpoint (scale on `InvocationsPerInstance`)
- [ ] GCP Vertex AI endpoint using the `google` provider
- [ ] Full ML infra stack: VPC + EC2 GPU training instance + S3 + endpoint

## Related Folders
- `cloud-deployment/aws-lambda-ml-inference-main/` — serverless alternative to SageMaker endpoints
- `mlops/mlflow-tracking-main/` — model registry that feeds artifact URIs into Terraform configs
- `cloud-deployment/docker-containers-main/` — Docker images deployed via Terraform ECS resources
