terraform {
  backend "s3" {
    bucket  = "ap-southeast-2-shaun-terraform-workflow"
    key     = "state/terraform.tfstate"
    region  = "ap-southeast-2"
    encrypt = true
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for region and account id
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Find the latest Amazon Linux 2023 ARM64 AMI for the current region.
data "aws_ami" "amazon_linux_2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name = "name"
    values = [
      "*amazon-linux-2023*",
      "*amzn-ami-2023*",
      "*al2023*",
    ]
  }
}

# Data source to check if the IAM role exists
data "aws_iam_role" "existing_ec2_ecr_access" {
  name = "ec2-ecr-access"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "${var.project_name}-vpc" })
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.project_name}-public-subnet" })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.project_name}-igw" })
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.tags, { Name = "${var.project_name}-public-rt" })
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "api" {
  name        = "${var.project_name}-api-sg"
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

  tags = merge(var.tags, { Name = "${var.project_name}-api-sg" })
}

# IAM Role and instance profile so EC2 can pull from ECR
resource "aws_iam_role" "ec2_ecr_access" {
  count = length(data.aws_iam_role.existing_ec2_ecr_access.id) == 0 ? 1 : 0
  name  = "ec2-ecr-access"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  count      = length(data.aws_iam_role.existing_ec2_ecr_access.id) == 0 ? 1 : 0
  role       = aws_iam_role.ec2_ecr_access[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = length(data.aws_iam_role.existing_ec2_ecr_access.id) == 0 ? aws_iam_role.ec2_ecr_access[0].name : data.aws_iam_role.existing_ec2_ecr_access.name
  
  tags = var.tags
}

# EC2 Instance (t4g.nano) that pulls the container on boot
resource "aws_instance" "api" {
  ami                    = data.aws_ami.amazon_linux_2023_arm.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.api.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker aws-cli
              systemctl start docker
              systemctl enable docker
              REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F '"' '{print $4}')
              aws ecr get-login-password --region $${REGION} | docker login --username AWS --password-stdin $(echo "${var.ecr_image_uri}" | cut -d/ -f1)
              docker pull ${var.ecr_image_uri}
              docker run -d -p 80:80 ${var.ecr_image_uri}
              EOF

  tags = merge(var.tags, {
    Name = "${var.project_name}-api"
  })
}

output "instance_public_ip" {
  value = aws_instance.api.public_ip
}