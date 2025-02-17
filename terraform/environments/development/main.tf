# variables.tf
variable "region" {
  default = "eu-west-2"
}






# Random password generation
resource "random_password" "ad_admin_password" {
  length  = 16
  special = true
}

resource "random_password" "user_passwords" {
  for_each = { for user in var.user_list : split("@", user)[0] => user }

  length  = 16
  special = true
}

resource "random_password" "rds_password" {
  length  = 16
  special = true
}

# main.tf
provider "aws" {
  region = var.region
}

# VPC and Network Configuration
resource "aws_vpc" "vpc_quantum_qb" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-quantum-qb"
  }
}

resource "aws_internet_gateway" "igw_qq" {
  vpc_id = aws_vpc.vpc_quantum_qb.id

  tags = {
    Name = "igw-qq"
  }
}

resource "aws_eip" "eip_nat_qq" {
  domain = "vpc"
}

# Public subnet for NAT Gateway
resource "aws_subnet" "subnet_nat_public_qq" {
  vpc_id                  = aws_vpc.vpc_quantum_qb.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-nat-public-qq"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_qq" {
  allocation_id = aws_eip.eip_nat_qq.id
  subnet_id     = aws_subnet.subnet_nat_public_qq.id

  tags = {
    Name = "nat-qq"
  }
}

# Private subnets
resource "aws_subnet" "subnet_trusted_private_qq" {
  count             = 2
  vpc_id            = aws_vpc.vpc_quantum_qb.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = "eu-west-2${count.index == 0 ? "a" : "b"}"

  tags = {
    Name = "subnet-trusted-private-qq-${count.index + 1}"
  }
}

# Route tables
resource "aws_route_table" "rtb_nat_public_qq" {
  vpc_id = aws_vpc.vpc_quantum_qb.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_qq.id
  }

  tags = {
    Name = "rtb-nat-public-qq"
  }
}

resource "aws_route_table" "rtb_trusted_private_qq" {
  vpc_id = aws_vpc.vpc_quantum_qb.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_qq.id
  }

  tags = {
    Name = "rtb-trusted-private-qq"
  }
}

# Active Directory
resource "aws_directory_service_directory" "dir_workspaces_qq" {
  name     = var.domain_name
  password = random_password.ad_admin_password.result
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = aws_vpc.vpc_quantum_qb.id
    subnet_ids = aws_subnet.subnet_trusted_private_qq[*].id
  }

  tags = {
    Name = "dir-workspaces-qq"
  }
}

# DHCP Options Set
resource "aws_vpc_dhcp_options" "dhcp_qq" {
  domain_name         = var.domain_name
  domain_name_servers = aws_directory_service_directory.dir_workspaces_qq.dns_ip_addresses

  tags = {
    Name = "dhcp-qq"
  }
}

# Workspace Directory
resource "aws_workspaces_directory" "wsdir_qq" {
  directory_id = aws_directory_service_directory.dir_workspaces_qq.id
  subnet_ids   = aws_subnet.subnet_trusted_private_qq[*].id
}
