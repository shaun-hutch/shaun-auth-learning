aws_region = "ap-southeast-2"
project_name = "auth-learning"
environment = "dev"
instance_type = "t4g.nano"
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
tags = {
  Project     = "auth-learning"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "shaun"
}