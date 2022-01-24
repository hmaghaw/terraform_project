provider "aws" {
  region = local.region
}

locals {
  region = "us-east-2"
}

resource "aws_vpc" "pdd_575_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "pdd 575 VPC"
  }
}
resource "aws_subnet" "pdd_575_public_subnet" {
  vpc_id            = aws_vpc.pdd_575_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${local.region}a"

  tags = {
    Name = "pdd_575 public subnet"
  }
}

resource "aws_subnet" "pdd_575_private_subnet" {
  vpc_id            = aws_vpc.pdd_575_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${local.region}a"

  tags = {
    Name = "pdd_575 private subnet"
  }
}
resource "aws_internet_gateway" "some_ig" {
  vpc_id = aws_vpc.pdd_575_vpc.id

  tags = {
    Name = "Some Internet Gateway"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.pdd_575_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.some_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.some_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}
resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.pdd_575_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.pdd_575_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "web_instance" {
  ami           = "ami-001089eb624938d9f"
  instance_type = "t2.micro"
  key_name      = "terraform"

  subnet_id                   = aws_subnet.pdd_575_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash -ex

  sudo yum install -y yum-utils
  sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
  sudo yum -y install terraform
  EOF

  tags = {
    "Name" : "Terraform instance"
    "jira" : "pdd-575"
    "src": "Windows"
  }
}