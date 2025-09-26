terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# Data sources for region and account id
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Find the latest Amazon Linux 2023 ARM64 AMI for the current region.
# This avoids hard-coding a region-specific AMI id which will not work across regions.
data "aws_ami" "amazon_linux_2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  # Try common name patterns for Amazon Linux 2023; if your account needs a different
  # pattern update the values accordingly.
  filter {
    name = "name"
    values = [
      "*amazon-linux-2023*",
      "*amzn-ami-2023*",
      "*al2023*",
    ]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "auth-learning-vpc"
  }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "auth-learning-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "auth-learning-igw" }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "auth-learning-public-rt" }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "api" {
  name        = "auth-learning-api-sg"
  description = "Security group for API instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_access" {
  name = "ec2-ecr-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.ec2_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_access.name
}

# EC2 Instance (t4g.nano)
resource "aws_instance" "api" {
  # Use the discovered Amazon Linux 2023 ARM64 AMI for the current region
  ami           = data.aws_ami.amazon_linux_2023_arm.id
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.public.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.api.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker aws-cli
              systemctl start docker
              systemctl enable docker
              # Login to ECR and run container
              aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
              docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/auth-learning-api:latest
              docker run -d -p 80:80 ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/auth-learning-api:latest
              EOF

  tags = { Name = "auth-learning-api" }
}

output "instance_public_ip" {
  value = aws_instance.api.public_ip
}