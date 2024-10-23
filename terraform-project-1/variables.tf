variable "ami" {

    default = "ami-066784287e358dad1"

}


variable "vpc" {

  default = "123"
    
}

variable "cidr" {
  default = "10.0.0.0/16"
}

variable "instance_type" {

    default = "t2.micro"
    
}

variable "instance_name" {

    default = "MyEc2"
    
}

variable "region" {

    default = "us-east-1"
    
}

variable "env" {

    default = "dev"
    
}

variable "user_data" {

     default = ""
    
}

variable "subnet_id1" {

     default = "subnet-0c12057e8a5301c75"
    
}

variable "subnet_id2" {

     default = "subnet-0f7308553bb94bac4"
    
}