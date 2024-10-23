variable "ami" {

    default = "ami-066784287e358dad1"

}

variable "instance_type" {

    default = "t2.micro"
    
}

variable "instance_name" {

    default = "MyEc2"
    
}

variable "region" {

    default = "us-west-1"
    
}

variable "env" {

    default = "dev"
    
}

variable "vpc" {

  default = "123"
    
}

variable "user_data" {

     default = ""
    
}

variable "subnet_id1" {

     default = "subnet-0c12057e8a5301c75"
    
}

variable "iam_instance_profile" {
  description = "The name of the IAM instance profile to attach to the EC2 instance"
  default = "ec2-instance-profile"
}