
resource "aws_security_group" "my_security_groups" {
    description = "Allow TLS inbound traffic and all outbound traffic"
    vpc_id = aws_vpc.main-vpc-for-learning.id

    tags = {
        Name = "${var.env}-Security-grp"
        Environment = var.env
    }

    #Inbound (ingress)
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Inbound Rule for SSH"
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP Port Enable/Open"
    }


    #Outbound (egress)
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Access over internet from our machine: means request goes outside."
    }
}

resource "aws_instance" "Kapil-instance_type_public" {
    
    #Count how many resources to  be created!!
    count = var.instance_count
    # Only run when these resources will be created...
    depends_on = [ aws_security_group.my_security_groups, aws_key_pair.key-for-learning ]
    # ADD key Pair
    key_name = aws_key_pair.key-for-learning.key_name
    # ADD Security Groups
    vpc_security_group_ids = [aws_security_group.my_security_groups.id]
    
    # Associate Public IP Address from    subnet CIDR range
    associate_public_ip_address = true

    instance_type = var.instance_type_public
    
    # ami = data.aws_ami.amazon_linux.id
    ami = var.ec2_ami_id

    user_data = file("K:/Learning/Terraform Daily-Prac/Multi Staging Infrastructure/Infrastructure/install_nginx.sh")

    # Root block storage, this has to be attach with ec2 machine
    root_block_device {
      volume_size = var.block_size
      volume_type = "gp3"
    }

    #Association of subnet
    subnet_id = aws_subnet.public.id

    tags = {
      Name = "${var.env}-${var.instance_type_public}-inside-public-subnet"
      Environment = var.env
    }

}

resource "aws_instance" "Kapil-instance_type_private" {
    
  count = var.env == "production" ? 0 : var.instance_count

    depends_on = [ aws_security_group.my_security_groups, aws_key_pair.key-for-learning ]

    key_name = aws_key_pair.key-for-learning.key_name
    
    vpc_security_group_ids = [aws_security_group.my_security_groups.id]
    

    associate_public_ip_address = true
    
    instance_type = var.instance_type_private
    
    # ami = data.aws_ami.amazon_linux.id
    ami = var.ec2_ami_id

    user_data = file("K:/Learning/Terraform Daily-Prac/Multi Staging Infrastructure/Infrastructure/install_nginx.sh")

    root_block_device {
      volume_size = var.block_size
      volume_type = "gp3"
    }

    #Association of subnet
    subnet_id = aws_subnet.private.id

    tags = {
      Name = "${var.env}-${var.instance_type_private}-inside-private-subnet"
      Environment = var.env
    }

}