# Multi-Staging AWS Infrastructure with Terraform

This project provisions AWS infrastructure for three environments using one reusable Terraform module:

- Development
- Testing
- Production

The root configuration in `main.tf` calls the reusable module in `Infrastructure/` once for each environment. Each module receives its own region, AMI ID, instance count, instance types, storage size, and environment name.

## Architecture

Each environment creates the following AWS resources:

- VPC
- Public subnet
- Private subnet
- Internet Gateway
- NAT Gateway and Elastic IP
- Route table and public subnet association
- Security group
- EC2 key pair
- EC2 instances
- S3 bucket

The intended network layout is:

```text
AWS Region
└── VPC
    ├── Public Subnet
    │   ├── EC2 instances
    │   ├── NAT Gateway
    │   └── Internet Gateway route
    └── Private Subnet
        └── Private resources
```

## Environment Configuration

The current values are defined in `main.tf`:

| Environment | AWS Region | Instance Count | Public EC2 | Private EC2 | Root Volume |
| --- | --- | ---: | ---: | ---: | ---: |
| Development | `ap-south-1` | 1 | 1 | 1 | 10 GB |
| Production | `us-east-1` | 2 | 2 | 0 | 20 GB |
| Testing | `us-east-2` | 1 | 1 | 1 | 15 GB |

Production intentionally creates zero private-subnet EC2 instances with this module rule:

```hcl
count = var.env == "production" ? 0 : var.instance_count
```

The public instances still use `var.instance_count` in every environment.

## Important Regional Rule

AWS resources are regional. An AMI, subnet, VPC, security group, key pair, EBS snapshot, or Elastic IP created in one region cannot automatically be used in another region.

For example, an AMI created in `ap-south-1` cannot be used to create an EC2 instance in `us-east-1` or `us-east-2`. Each environment must receive an AMI ID that exists in its own region. The current `main.tf` supplies separate AMI IDs for Development, Production, and Testing for this reason.

Availability Zones also belong to a specific region. The subnet configuration currently builds the AZ from the selected region:

```hcl
availability_zone = "${var.region}a"
```

The resulting AZ must exist and be available in that region. For more flexible production deployments, use a data source to discover available AZs instead of assuming the `a` suffix.

See [Result.md](Result.md) for the detailed regional resource lesson.

## Project Structure

```text
Multi Staging Infrastructure/
├── main.tf                         # Root module and environment definitions
├── Readme.md
├── Result.md                       # Regional resource learning notes
├── Instruction.md                  # AWS and Terraform instructions
└── Infrastructure/                 # Reusable child module
    ├── terraform.tf                # AWS provider requirement
    ├── provider.tf                 # Provider region from var.region
    ├── variable.tf                 # Module input variables
    ├── vpc.tf                      # VPC
    ├── subnet.tf                   # Public and private subnets
    ├── igw.tf                      # Internet Gateway
    ├── nat-gw.tf                   # NAT Gateway and Elastic IP
    ├── route-table.tf              # Routes and associations
    ├── ec2.tf                      # Security group and EC2 instances
    ├── keypair.tf                  # EC2 key pair
    ├── s3.tf                       # S3 bucket
    └── install_nginx.sh            # EC2 user-data script
```

## Prerequisites

Install and configure:

- Terraform
- AWS CLI
- An AWS account
- AWS credentials with permission to create the listed resources
- An EC2 key pair or the key material expected by `keypair.tf`

Check the installations:

```powershell
terraform version
aws --version
aws sts get-caller-identity
```

## Deploy

Run Terraform from the project root, where `main.tf` is located:

```powershell
cd "K:\Learning\Terraform Daily-Prac\Multi Staging Infrastructure"
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Review the plan carefully before applying, especially because the configuration creates resources in three AWS regions.

To remove the managed infrastructure:

```powershell
terraform destroy
```

## State Management

Terraform stores the root configuration state in `terraform.tfstate` unless a backend is configured. Do not edit the state file manually.

For real environments:

- Use separate state for Development, Testing, and Production.
- Store state in an encrypted S3 backend.
- Use DynamoDB or the supported Terraform locking mechanism for state locking.
- Do not run multiple Terraform operations against the same state at the same time.
- Back up state securely and do not commit sensitive state files to Git.

## Current Learning Notes

This project demonstrates:

- Reusing one Terraform module for multiple environments
- Passing environment-specific variables to child modules
- Creating resources in different AWS regions
- Understanding regional AMI and Availability Zone limitations
- Using `count` to disable production private instances
- Building VPC networking with public and private subnets
- Managing Terraform state and reviewing plans

## Security and Production Considerations

This is a learning project and should be hardened before production use:

- Restrict SSH access instead of allowing `0.0.0.0/0`.
- Restrict HTTP ingress to the required sources.
- Use private key files securely and never commit them.
- Use private subnets without public IP address assignment for private resources.
- The current private EC2 resource sets `associate_public_ip_address = true`; change this to `false` if private instances are enabled later.
- Use region-specific or dynamically discovered AMIs.
- Use separate state and backend configuration per environment.
- Add outputs, monitoring, backups, and resource tagging standards.
