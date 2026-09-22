# AWS Infrastructure with Terraform

This project provisions AWS infrastructure using **Terraform** for three separate environments:

* **Development**
* **Testing**
* **Production**

The goal of this project is to build a reusable and environment-specific infrastructure setup using Terraform, following common Infrastructure as Code (IaC) practices.

## Environments

| Environment | Purpose                                           |
| ----------- | ------------------------------------------------- |
| Development | Used for development and experimentation          |
| Testing     | Used for testing and validation before production |
| Production  | Used to host production workloads                 |

Each environment can have its own infrastructure configuration, resources, networking, and security settings.

## Infrastructure

The infrastructure includes the following AWS resources:

* VPC
* Public and Private Subnets
* Internet Gateway
* NAT Gateway
* Route Tables and Routes
* Security Groups
* EC2 Instances
* EC2 Key Pair
* S3 Bucket

### High-Level Architecture

```text
                         AWS
                          |
                         VPC
                          |
          +---------------+---------------+
          |                               |
     Public Subnet                   Private Subnet
          |                               |
     +----+----+                    +-----+-----+
     |         |                    |           |
    EC2      NAT GW                EC2       Resources
     |         |
     +----+----+
          |
     Internet Gateway
          |
       Internet
```

> The exact architecture may vary between Development, Testing, and Production environments.

## Terraform Structure

A possible project structure is:

```text
terraform-infrastructure/
│
├── environments/
│   ├── development/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   │
│   ├── testing/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   │
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
├── modules/
│   ├── vpc/
│   ├── subnet/
│   ├── route/
│   ├── security-group/
│   ├── ec2/
│   ├── key-pair/
│   └── s3/
│
├── README.md
└── instruction.md
```

## Requirements

Before using this project, install and configure:

* Terraform
* AWS CLI
* AWS account
* AWS credentials
* SSH key pair or Terraform-managed EC2 key pair

Verify Terraform:

```bash
terraform version
```

Verify AWS CLI:

```bash
aws --version
```

Verify AWS credentials:

```bash
aws sts get-caller-identity
```

## Deployment

Navigate to the required environment:

```bash
cd environments/development
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Review the infrastructure changes:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

To destroy the environment:

```bash
terraform destroy
```

The same process can be used for Testing and Production.

## Environment Example

Development:

```bash
cd environments/development
terraform init
terraform plan
terraform apply
```

Testing:

```bash
cd environments/testing
terraform init
terraform plan
terraform apply
```

Production:

```bash
cd environments/production
terraform init
terraform plan
terraform apply
```

## Terraform State

Terraform state keeps track of the infrastructure resources managed by Terraform.

For a real-world setup, Terraform state should be stored remotely, for example in an **Amazon S3 bucket**.

State locking should also be configured where appropriate to prevent multiple Terraform operations from modifying the same state simultaneously.

## Important Notes

* Do not commit AWS access keys or secret credentials to Git.
* Do not commit private SSH keys.
* Use separate Terraform state for each environment.
* Review `terraform plan` before applying changes.
* Production infrastructure should be changed carefully.
* Use variables instead of hardcoding environment-specific values.
* Reusable Terraform modules should be used where possible.

## Project Goal

This project is intended as a practical Infrastructure as Code project for learning and practicing:

* Terraform
* AWS networking
* EC2 provisioning
* Infrastructure modularization
* Environment separation
* Terraform state management
* Security configuration
* AWS infrastructure automation
