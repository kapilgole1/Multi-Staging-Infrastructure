# Result: AWS Region, Availability Zone, and Resource Availability

## What I Learned

AWS resources are not automatically available in every region. A resource must be created with values that exist in the same AWS region as the Terraform provider.

In this project, each environment uses a different region:

| Environment | Region |
| --- | --- |
| Development | `ap-south-1` |
| Production | `us-east-1` |
| Testing | `us-east-2` |

The AWS provider selects the region with:

```hcl
provider "aws" {
  region = var.region
}
```

## Availability Zones

An Availability Zone (AZ) belongs to a specific region. For example:

```text
ap-south-1a belongs to ap-south-1
us-east-1a belongs to us-east-1
us-east-2a belongs to us-east-2
```

An AZ from one region cannot be used in another region. In this project, the subnet AZ is built from the selected region:

```hcl
availability_zone = "${var.region}a"
```

This works only when the resulting AZ exists and is available for the AWS account in that region. AZ names can also map differently between AWS accounts, so production code should preferably discover valid AZs instead of assuming a fixed suffix.

## The EC2 AMI Problem

The EC2 AMI ID used in the configuration was created in `ap-south-1`, but the same AMI ID was passed to environments in other regions such as `us-east-1` and `us-west-1`.

Example of the invalid assumption:

```text
AMI created in: ap-south-1
EC2 requested in: us-east-1 or us-west-1
```

AMI IDs are region-specific. An AMI ID from `ap-south-1` does not exist in `us-east-1` or `us-west-1` unless the image is copied to that region. Therefore AWS cannot create the EC2 instance and Terraform reports errors such as:

```text
couldn't find resource
InvalidAMI.NotFound
```

The same rule applies to other regional resources, including subnets, VPCs, security groups, key pairs, EBS snapshots, and Elastic IPs. A resource created in one region cannot be referenced directly from another region.

## Correct Approaches

### 1. Use a region-specific AMI variable

```hcl
variable "ec2_ami_id" {
  type = string
}
```

Then provide an AMI that exists in each target region:

```hcl
module "Infrastructure-for-Production" {
  region     = "us-east-1"
  ec2_ami_id = "ami-valid-in-us-east-1"
}
```

### 2. Discover an AMI in the selected region

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "example" {
  ami = data.aws_ami.amazon_linux.id
}
```

The data source runs through the provider configured for that module, so it searches for an AMI in the correct region.

### 3. Copy the AMI to another region

An AMI can be copied from `ap-south-1` to `us-east-1` or another region. The copied image receives a new AMI ID in the destination region, and that new ID must be used when creating the EC2 instance there.

## Practical Checklist

Before creating an EC2 instance:

1. Confirm the Terraform provider region.
2. Confirm the subnet and Availability Zone belong to that region.
3. Confirm the AMI exists and is available in that region.
4. Confirm the instance type is offered in that region and AZ.
5. Confirm the key pair and security group were created in the same region.
6. Run `terraform plan` and inspect the selected region and AMI before applying.

## Final Result

The EC2 instances were not created in the other environments because a region-specific AMI from `ap-south-1` was used for regions where that AMI ID did not exist. The fix is to use a valid AMI per region, discover the AMI dynamically, or copy the original AMI into each required region.
