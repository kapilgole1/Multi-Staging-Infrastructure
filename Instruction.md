# Infrastructure Instructions

This document explains how the Multi-Staging AWS Terraform project works and how to deploy it safely.

## 1. Project Overview

The project creates the same base infrastructure for three environments by calling one reusable child module three times from `main.tf`:

- Development: `ap-south-1`
- Production: `us-east-1`
- Testing: `us-east-2`

The reusable module is located in `Infrastructure/`. The root module passes environment-specific values such as the AWS region, AMI ID, instance count, instance type, and root volume size.

## 2. Project Structure

```text
Multi Staging Infrastructure/
├── main.tf
├── Readme.md
├── Result.md
├── Instruction.md
└── Infrastructure/
    ├── terraform.tf
    ├── provider.tf
    ├── variable.tf
    ├── vpc.tf
    ├── subnet.tf
    ├── igw.tf
    ├── nat-gw.tf
    ├── route-table.tf
    ├── ec2.tf
    ├── keypair.tf
    ├── s3.tf
    └── install_nginx.sh
```

## 3. Environment Values

The current environment values are defined in `main.tf`:

| Environment | Region | Instance Count | Public EC2 | Private EC2 | AMI |
| --- | --- | ---: | ---: | ---: | --- |
| Development | `ap-south-1` | 1 | 1 | 1 | `ami-01a00762f46d584a1` |
| Production | `us-east-1` | 2 | 2 | 0 | `ami-0b6d9d3d33ba97d99` |
| Testing | `us-east-2` | 1 | 1 | 1 | `ami-0e5497a77ef21b5ac` |

Production private instances are intentionally disabled in `ec2.tf`:

```hcl
count = var.env == "production" ? 0 : var.instance_count
```

The public EC2 resource still uses `var.instance_count`, so Production creates two public instances.

## 4. Network Architecture

Each environment creates its own VPC and networking resources:

```text
AWS Region
└── VPC: 10.0.0.0/16
    ├── Public Subnet: 10.0.1.0/24
    │   ├── Public EC2 instances
    │   ├── NAT Gateway
    │   └── Internet Gateway route
    └── Private Subnet: 10.0.2.0/24
        └── Private EC2 instances when enabled
```

### VPC

The VPC provides an isolated network for each environment. Its subnets, route tables, security group, NAT Gateway, and EC2 instances are created inside that VPC.

### Public Subnet

The public subnet is configured with:

```hcl
map_public_ip_on_launch = true
```

It uses the public route table and Internet Gateway so resources can communicate directly with the internet when a public IP is assigned.

### Private Subnet

The private subnet is intended for resources that should not be directly reachable from the internet. If private EC2 instances are enabled, outbound internet access should go through the NAT Gateway.

The current subnet file sets `map_public_ip_on_launch = true` for the private subnet, and the private EC2 resource sets `associate_public_ip_address = true`. These settings should be changed to `false` before using private instances in a real production design.

## 5. Region and Availability Zone Rules

AWS resources are regional. A resource created in one region cannot automatically be used in another region.

Examples:

- An AMI from `ap-south-1` cannot be used directly in `us-east-1`.
- A subnet from `us-east-1` cannot be attached to a VPC in `us-east-2`.
- A key pair and security group must exist in the region where the EC2 instance is created.
- EBS snapshots, Elastic IPs, and many other resources are also region-specific.

The AMI passed to each module must exist in that module's region. If an AMI must be used in another region, copy the AMI first; AWS assigns a new AMI ID in the destination region.

The current subnets derive their Availability Zone from the region:

```hcl
availability_zone = "${var.region}a"
```

An Availability Zone belongs to one region only. The resulting AZ must be available in the selected region and account. A more flexible design should discover available AZs with a data source instead of assuming the `a` suffix.

## 6. AWS Services

### Internet Gateway

The Internet Gateway connects the VPC to the public internet. The public route table sends internet-bound traffic to the Internet Gateway.

### NAT Gateway

The NAT Gateway allows instances in a private subnet to start outbound connections without accepting unsolicited inbound internet connections. NAT Gateways have an AWS usage cost.

### Route Tables

Route tables control traffic flow:

```text
Public route:  0.0.0.0/0 -> Internet Gateway
Private route: 0.0.0.0/0 -> NAT Gateway
```

The current route configuration should be reviewed before enabling private EC2 instances, especially if private route-table association is added later.

### Security Group

The EC2 security group currently allows:

| Direction | Protocol | Port | Source |
| --- | --- | ---: | --- |
| Inbound | TCP | 22 | `0.0.0.0/0` |
| Inbound | TCP | 80 | `0.0.0.0/0` |
| Outbound | All | All | `0.0.0.0/0` |

For production, restrict SSH port 22 to a trusted IP or management network. Keep HTTP and outbound access limited to the actual application requirements.

### EC2

The EC2 resources receive:

- AMI ID from `var.ec2_ami_id`
- Instance type from the environment module
- Subnet placement
- Security group
- Terraform-managed key pair
- Root `gp3` volume
- Nginx installation script through `user_data`
- Environment and name tags

The Nginx script is loaded from `Infrastructure/install_nginx.sh`.

### S3

Each environment currently receives the configured S3 bucket name. S3 can store application objects or infrastructure artifacts. For Terraform state, use a dedicated remote backend bucket with encryption, versioning, and controlled access rather than mixing application data and state casually.

## 7. Prerequisites

Install and configure:

- Terraform
- AWS CLI
- An AWS account
- AWS credentials with permission to create the required resources
- A public SSH key for the Terraform-managed EC2 key pair

Verify the tools and credentials:

```powershell
terraform version
aws --version
aws sts get-caller-identity
```

## 8. Terraform Workflow

Run all commands from the project root, where `main.tf` is located:

```powershell
cd "K:\Learning\Terraform Daily-Prac\Multi Staging Infrastructure"
```

### Initialize

```powershell
terraform init
```

Initialization downloads the AWS provider and prepares the local module.

### Format

```powershell
terraform fmt -recursive
```

### Validate

```powershell
terraform validate
```

### Review the Plan

```powershell
terraform plan
```

Check the plan for:

- Correct environment regions
- Correct AMI IDs for those regions
- Production private EC2 count equal to zero
- Expected public and private subnet placement
- Unexpected resource replacement or destruction

### Apply

```powershell
terraform apply
```

Review the plan and type `yes` when Terraform asks for confirmation.

### Destroy

Destroying the root configuration removes resources across all three environments:

```powershell
terraform destroy
```

Use this carefully, especially when the configuration manages production resources.

## 9. Troubleshooting

### AMI not found

Error examples:

```text
InvalidAMINotFound
couldn't find resource
```

Check that the AMI ID exists in the same region as the module provider. AMI IDs are not global.

### Availability Zone not found

Check that `${var.region}a` exists in the selected region. Use AWS CLI or a Terraform availability-zone data source to discover valid zones.

### State lock error

Do not run multiple Terraform commands against the same state. Wait for the other Terraform operation to finish. If a stale lock remains, verify that no Terraform process is running before removing or repairing the lock.

### Resource exists in AWS but not in state

Use `terraform import` to bring an existing resource under management. Do not manually edit `terraform.tfstate`.

### Resource is in state but missing from AWS

Confirm the resource is truly deleted, then remove only the stale address with `terraform state rm`. Run `terraform plan` afterward so Terraform can propose the correct replacement.

## 10. State and Security Practices

For learning, local state may be used. For shared or production work:

- Use separate state for Development, Testing, and Production.
- Store state in an encrypted S3 backend.
- Enable state versioning and locking.
- Never commit `terraform.tfstate`, private keys, credentials, or secrets.
- Review every production plan before applying it.
- Use least-privilege AWS IAM permissions.
- Restrict SSH access and avoid public IPs on private resources.

## 11. Learning Goals

This project demonstrates:

- Terraform modules and environment-specific inputs
- AWS provider regions
- Region-specific AMIs and Availability Zones
- VPC, subnet, route, NAT, and Internet Gateway configuration
- EC2 provisioning with `count`
- Conditional resource creation for Production
- Terraform planning, state, and troubleshooting
