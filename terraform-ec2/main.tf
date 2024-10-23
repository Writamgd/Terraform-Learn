module "ec2_instance" { 
  source = "./modules/ec2_instance" 
  ami = var.ami
  vpc = data.aws_vpc.vpc.id
  subnet_id1       = var.subnet_id1

  env = var.env
  instance_type = var.instance_type 
  instance_name = var.instance_name 
  region = var.region
  user_data = data.template_file.user_data.rendered
  #depends_on = [aws_lb.example]
}

data "template_file" "user_data" {
  template = file("user-data.sh")
}



/*data "aws_ami" "ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${var.env}-linux"]
  }
}*/

data "aws_vpc" "vpc" {

  filter {
    name   = "tag:Name"
    values = ["${var.env}-vpc"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_security_group"
  description = "Security group for the ALB"
  vpc_id      = data.aws_vpc.vpc.id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [var.subnet_id1, var.subnet_id2]

  enable_deletion_protection = false
  enable_http2              = true
 

  tags = {
    Name = "example-alb"
  }
}

resource "aws_lb_target_group" "example" {
  name     = "example-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id # Replace with your VPC ID
  health_check {
    interval            = 30
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }

  tags = {
    Name = "example-target-group"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = module.ec2_instance.instance_id
  port             = 80
}

terraform {
  backend "s3" {
    bucket = "writambuck"
    key    = "home/ec2-user/terraform-ec2/terraform.tfstate"
    region = "us-east-1"
  }
}

