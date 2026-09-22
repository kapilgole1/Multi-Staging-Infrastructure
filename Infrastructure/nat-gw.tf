# 1. Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-gateway-eip"
  }
}


# 2. Create the NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.env}-main-nat-gateway"
    Environment = var.env
  }

  depends_on = [aws_internet_gateway.main-igw]
}