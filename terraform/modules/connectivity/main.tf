locals {
    vpc_name = var.vpc_name
    public_subnet_name = "subnet-public-qq"
    vpc_cidr = "10.0.0.0/16"
    public_subnet_cidr = "10.0.0.0/24"
    trusted_subnets_name = ["subnet-trusted-0", "subnet-trusted-1"]
    untrusted_subnets_name = ["subnet-untrusted-0", "subnet-untrusted-1"]
    trusted_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
    untrusted_subnets_cidr = ["10.0.2.0/24", "10.0.22.0/24"]
}

resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.vpc_name
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = local.public_subnet_name
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "eip-nat-qq"
  }
}

resource "aws_internet_gateway" "qq" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw-qq"
  }
}

resource "aws_nat_gateway" "qq" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet_public.id
  tags = {
    Name = "nat-qq"
  }
}

resource "aws_route_table" "nat_gateway" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.qq.id
  }
}

resource "aws_route_table_association" "nat_gateway" {
  subnet_id = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.nat_gateway.id
}

resource "aws_subnet" "subnets_trusted" {
  count = 2
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.trusted_subnets_cidr[count.index]
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-2${count.index == 0 ? "a" : "b"}"

  tags = {
    Name = local.trusted_subnets_name[count.index]
  }
}

resource "aws_route_table" "trusted" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.qq.id
  }
}

resource "aws_route_table_association" "trusted" {
  count = 2
  subnet_id = aws_subnet.subnets_trusted[count.index].id
  route_table_id = aws_route_table.trusted.id
}

resource "aws_security_group" "sg_workspaces_qq" {
  name        = "workspaces-sg-qq"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
