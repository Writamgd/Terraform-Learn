module "ec2_instance" { 
  source = "/home/ec2-user/terraform-ec2/modules/ec2_instance" 
  ami = var.ami
  vpc = aws_vpc.myvpc.id
  subnet_id1       = aws_subnet.public_subnet.id

  #env = var.env
  instance_type = var.instance_type 
  instance_name = var.instance_name 
  region = var.region
  user_data = data.template_file.user_data.rendered
  #iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  #depends_on = [aws_alb.my_alb]
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr

  tags = {
      Name = "main-vpc"
    }

}


data "template_file" "user_data" {
  template = file("user-data.sh")
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_security_group" "public_access" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

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

  tags = {
    Name = "public-access-sg"
  }
}

resource "aws_security_group" "internal" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    security_groups = [aws_security_group.public_access.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "internal-sg"
  }
}

terraform {
  backend "s3" {
    bucket = "writambuck"
    key    = "home/ec2-user/terraform-project/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_internet_gateway" "igw" {  
  vpc_id = aws_vpc.myvpc.id  

  tags = {  
    Name = "MyIGW"  
  }  
}  

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_eip" "nat_eip" {  
  depends_on = [aws_internet_gateway.igw]  
}  

resource "aws_nat_gateway" "nat" {  
  allocation_id = aws_eip.nat_eip.id  
  subnet_id    = aws_subnet.public_subnet.id  

  tags = {  
    Name = "NATGateway"  
  }  
}  

resource "aws_route_table" "private_route_table" {  
  vpc_id = aws_vpc.myvpc.id  

  route {  
    cidr_block = "0.0.0.0/0"  
    nat_gateway_id = aws_nat_gateway.nat.id
  }

}

resource "aws_alb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_access.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.private.id]

  enable_deletion_protection = false
  enable_http2              = true

  tags = {
    Name = "MyALB"
  }
}

resource "aws_alb_target_group" "tg" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    interval            = 30
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.tg.arn
  }
}

resource "aws_alb_target_group_attachment" "web" {
  target_group_arn = aws_alb_target_group.tg.arn
  target_id        = module.ec2_instance.instance_id
  port             = 80
}
