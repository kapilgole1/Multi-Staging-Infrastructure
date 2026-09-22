variable "env" {
    description = "This section contain Environment value."
    type = string
}

variable "region" {
    description = "This section contain region of my infrastructure."
    type = string
}

variable "instance_count" {
    description = "This section contain number of instance to be deployed/created."
    type = number
}

variable "ec2_ami_id" {
    # default = "ami-01a00762f46d584a1"
    description = "This section contain AMI of the machine."
    type = string
  
}

variable "instance_type_public" {
    description = "This section contain instance type of my machine."
    type = string
}

variable "instance_type_private" {
    description = "This section contain instance type of my machine."
    type = string
}

variable "block_size" {
    description = "This section contain size of block root storage."
    type = number
}

variable "bucket" {
    description = "This section contain bucket name."
    type = string
}