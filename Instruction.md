# Infrastructure Instructions

This document describes the AWS services used in this Terraform infrastructure and their purpose.

The infrastructure is divided into three environments:

* Development
* Testing
* Production

Each environment is managed independently using Terraform.

---

# AWS Services Used

## 1. VPC

**Amazon VPC (Virtual Private Cloud)** provides the isolated network in which the infrastructure is deployed.

The VPC contains:

* Subnets
* Route tables
* Internet Gateway
* NAT Gateway
* Security Groups
* EC2 instances

Example:

```text
VPC
│
├── Public Subnet
│
├── Private Subnet
│
├── Route Tables
│
├── Internet Gateway
│
└── NAT Gateway
```

The VPC forms the foundation of the AWS networking architecture.

---

# 2. Subnets

Subnets divide the VPC into smaller network segments.

This infrastructure can use:

* Public subnets
* Private subnets

### Public Subnet

A public subnet contains resources that need direct internet connectivity through an Internet Gateway.

Example:

```text
Internet
   |
Internet Gateway
   |
Public Subnet
   |
EC2
```

### Private Subnet

A private subnet does not have a direct route to the Internet Gateway.

If resources inside a private subnet need outbound internet access, they can use a NAT Gateway.

```text
Private EC2
    |
Private Subnet
    |
NAT Gateway
    |
Internet Gateway
    |
Internet
```

---

# 3. Internet Gateway

An **Internet Gateway (IGW)** allows resources in a VPC to communicate with the public internet.

It is attached to the VPC.

For a public subnet, the route table normally contains a route such as:

```text
0.0.0.0/0 → Internet Gateway
```

Example:

```text
Internet
    |
   IGW
    |
   VPC
    |
Public Subnet
    |
   EC2
```

---

# 4. Route Tables

Route tables determine where network traffic is sent.

A route table contains routes such as:

```text
Destination       Target
0.0.0.0/0         Internet Gateway
```

For a private subnet using a NAT Gateway:

```text
Destination       Target
0.0.0.0/0         NAT Gateway
```

Typical architecture:

```text
Public Route Table
        |
        +---- 0.0.0.0/0 → IGW
        |
   Public Subnet


Private Route Table
        |
        +---- 0.0.0.0/0 → NAT Gateway
        |
   Private Subnet
```

---

# 5. NAT Gateway

A **NAT Gateway** allows resources in private subnets to initiate outbound connections to the internet without allowing unsolicited inbound connections from the internet.

Example:

```text
Private EC2
     |
Private Subnet
     |
Route Table
     |
NAT Gateway
     |
Internet Gateway
     |
Internet
```

A common use case is allowing a private EC2 instance to download packages or updates.

For example:

```bash
sudo apt update
```

The EC2 instance can access the internet through the NAT Gateway while remaining in a private subnet.

> NAT Gateway has an AWS cost, so it should be used carefully in learning environments.

---

# 6. Security Groups

Security Groups act as virtual firewalls for resources such as EC2 instances.

Rules determine which traffic is allowed.

Example:

```text
Inbound
--------------------------------
SSH       TCP 22     Your IP
HTTP      TCP 80     0.0.0.0/0
HTTPS     TCP 443    0.0.0.0/0
```

Outbound traffic can also be controlled.

For example, an EC2 security group may allow:

```text
Internet
   |
   | TCP 80
   ↓
EC2
```

Security Groups are **stateful**, meaning return traffic for an allowed connection is automatically permitted.

---

# 7. EC2

**Amazon EC2 (Elastic Compute Cloud)** provides virtual servers.

This infrastructure uses EC2 instances to run workloads inside the VPC.

An EC2 instance can be deployed into either:

* Public subnet
* Private subnet

Example:

```text
VPC
│
├── Public Subnet
│      |
│      └── EC2
│
└── Private Subnet
       |
       └── EC2
```

Terraform can manage:

* AMI
* Instance type
* Subnet
* Security Group
* Key Pair
* Root volume
* Tags
* User data

Example Terraform resource:

```hcl
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  security_groups = [
    aws_security_group.example.id
  ]

  tags = {
    Name        = "example-server"
    Environment = var.environment
  }
}
```

---

# 8. Key Pair

An EC2 Key Pair is used for SSH access to Linux EC2 instances.

Example:

```bash
ssh -i my-key.pem ubuntu@<EC2_PUBLIC_IP>
```

Terraform can create or reference an AWS EC2 Key Pair.

Example:

```hcl
resource "aws_key_pair" "example" {
  key_name   = "example-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

The private key should never be committed to Git.

---

# 9. S3

**Amazon S3 (Simple Storage Service)** is object storage.

In this infrastructure, S3 can be used for purposes such as:

* Terraform remote state
* Terraform state backups/versioning
* Application logs
* Configuration files
* Backup files
* Infrastructure artifacts

For Terraform state, an S3 bucket can be configured as the remote backend.

Example:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform/state"
    region = "ap-south-1"
  }
}
```

For multiple environments, the state should be separated so that Development, Testing, and Production do not accidentally use the same state.

Example:

```text
S3 Bucket
│
└── terraform-state/
    │
    ├── development/
    │   └── terraform.tfstate
    │
    ├── testing/
    │   └── terraform.tfstate
    │
    └── production/
        └── terraform.tfstate
```

---

# Environment Architecture

Each environment represents a separate deployment of the infrastructure.

```text
AWS
│
├── Development
│   ├── VPC
│   ├── Subnets
│   ├── Route Tables
│   ├── IGW
│   ├── NAT Gateway
│   ├── Security Groups
│   └── EC2
│
├── Testing
│   ├── VPC
│   ├── Subnets
│   ├── Route Tables
│   ├── IGW
│   ├── NAT Gateway
│   ├── Security Groups
│   └── EC2
│
└── Production
    ├── VPC
    ├── Subnets
    ├── Route Tables
    ├── IGW
    ├── NAT Gateway
    ├── Security Groups
    └── EC2
```

# Terraform Workflow

For each environment:

### 1. Initialize

```bash
terraform init
```

### 2. Format

```bash
terraform fmt
```

### 3. Validate

```bash
terraform validate
```

### 4. Plan

```bash
terraform plan
```

### 5. Apply

```bash
terraform apply
```

### 6. Destroy

When the environment is no longer required:

```bash
terraform destroy
```

# Recommended Order of Infrastructure

Terraform automatically determines dependencies, but conceptually the infrastructure can be understood in this order:

```text
VPC
 ↓
Subnets
 ↓
Internet Gateway
 ↓
Route Tables
 ↓
NAT Gateway
 ↓
Security Groups
 ↓
Key Pair
 ↓
EC2
 ↓
S3 / Terraform State
```

The actual Terraform dependency graph may differ because some resources can be created independently.

# Environment Separation

Development, Testing, and Production should have separate configuration and state.

Example:

```text
Development
    ↓
development.tfvars
    ↓
development state

Testing
    ↓
testing.tfvars
    ↓
testing state

Production
    ↓
production.tfvars
    ↓
production state
```

This prevents changes in one environment from unintentionally affecting another environment.

# Security Guidelines

1. Never commit AWS access keys to Git.
2. Never commit `.pem` private keys.
3. Do not hardcode secrets in Terraform files.
4. Restrict SSH access to trusted IP addresses.
5. Avoid `0.0.0.0/0` for SSH unless specifically required.
6. Review Terraform plans before applying changes.
7. Keep Production state separate from Development and Testing.
8. Enable appropriate S3 security controls and versioning for Terraform state.
9. Use IAM permissions following least privilege.
10. Destroy unused development resources to avoid unnecessary AWS costs.

# Project Objective

The objective of this project is to practice building a complete AWS infrastructure using Terraform while learning:

* AWS networking
* VPC architecture
* Public and private subnets
* Routing
* Internet Gateway
* NAT Gateway
* Security Groups
* EC2 provisioning
* SSH access
* S3
* Terraform state
* Environment separation
* Terraform modules
* Infrastructure as Code
