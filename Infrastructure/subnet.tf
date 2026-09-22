# Public Subnet
resource "aws_subnet" "public" {
    vpc_id                  = aws_vpc.main-vpc-for-learning.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "${var.region}a"
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.env}-public-subnet"
        # Name = "${var.env}-public-instance-${count.index}"
        Environment = "${var.env}"
    }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main-vpc-for-learning.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
        Name = "${var.env}-private-subnet"
        # Name = "${var.env}-public-instance-${count.index}"
        Environment = "${var.env}"
    }
}