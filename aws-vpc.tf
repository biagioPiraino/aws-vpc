# Initialize terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# Define variables
variable "environment_tag" {
  default = "Development"
}

variable "region_deployment" {
  default = "eu-west-1"
}

# Configure the AWS Provider
provider "aws" {
  region     = var.region_deployment
  access_key = "" # Add an access key
  secret_key = "" # Add a secret key
}

# Declare availability zones data source
data "aws_availability_zones" "available" {
  state = "available"
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC"
    Environment = var.environment_tag
  }  
}

# Create 2 public and private subnets in 2 different AZs
resource "aws_subnet" "public-subnet" {
  count = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = "10.0.${count.index + 2}.0/24"
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
    Environment = var.environment_tag
  }
}

resource "aws_subnet" "private-subnet" {
  count = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-${count.index}"
    Environment = var.environment_tag
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "internet-gateway"
    Environment = var.environment_tag
  }
}

# Create a route table
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "route-table"
    Environment = var.environment_tag
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "route-table-association" {
  count = 2
  route_table_id = aws_route_table.route-table.id
  subnet_id = aws_subnet.public-subnet.*.id[count.index]
}