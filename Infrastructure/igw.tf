resource "aws_internet_gateway" "main-igw" {
    vpc_id = aws_vpc.main-vpc-for-learning.id

    tags = {
        Name = "${var.env}-igw"
        Environment = var.env
    }
}