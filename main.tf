module "Infrastructure-for-Development" {
    source = "./Infrastructure"
    
    env = "development"

    region = "ap-south-1"

    instance_count = 1

    instance_type_private = "t3.micro"
    instance_type_public = "t3.micro"

    ec2_ami_id = "ami-01a00762f46d584a1"

    block_size = 10

    bucket = "aggresive-learning-at-night-2am"
}

module "Infrastructure-for-Production" {
    source = "./Infrastructure"
    
    env = "production"

    region = "us-east-1"

    instance_count = 2

    instance_type_private = "t3.micro"
    instance_type_public = "t3.micro"

    ec2_ami_id = "ami-0b6d9d3d33ba97d99"

    block_size = 20

    bucket = "aggresive-learning-at-night-2am"
}

module "Infrastructure-for-Testing" {
    source = "./Infrastructure"
    
    env = "testing"

    region = "us-east-2"

    instance_count = 1

    instance_type_private = "t3.micro"
    instance_type_public = "t3.micro"

    ec2_ami_id = "ami-0e5497a77ef21b5ac"

    block_size = 15

    bucket = "aggresive-learning-at-night-2am"
}