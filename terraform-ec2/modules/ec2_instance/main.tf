provider "aws" {
	region = var.region
}

resource "aws_instance" "myec2" {
  ami                  = var.ami
  instance_type        = var.instance_type
  #env                  = var.env
  user_data            =var.user_data
  subnet_id            = var.subnet_id1
  #iam_instance_profile = var.iam_instance_profile
  
  tags = { Name = var.instance_name}  
}

