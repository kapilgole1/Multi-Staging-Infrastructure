resource "aws_route_table" "public-route-table-for-public-subnet" {
    vpc_id = aws_vpc.main-vpc-for-learning.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main-igw.id
    }

    tags = {
        Name = "${var.env}-public-route-table"
        Environment = "${var.env}"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public-route-table-for-public-subnet.id
}