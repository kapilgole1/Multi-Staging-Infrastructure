#Create VPC
resource "aws_vpc" "main-vpc-for-learning" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true   # Provide dns support
  enable_dns_hostnames = true   # help to resolve dns hostnames for ex=>   ://amazom.com

  tags = {
    Name = "${var.env}-vpc-for-learning"
    Environment = "${var.env}"
  }
}



