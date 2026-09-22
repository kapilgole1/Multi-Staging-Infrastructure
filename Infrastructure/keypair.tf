resource "aws_key_pair" "key-for-learning" {
    key_name = "${var.env}-terraform-key-ec2"
    public_key = file("K:/Learning/Terraform Daily-Prac/Multi Staging Infrastructure/ssh-key-pair.pub")
}