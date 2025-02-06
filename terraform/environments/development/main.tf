provider "aws" {
  region = var.region
}

# Custom VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "CustomVPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainIGW"
  }
}

# Subnets
resource "aws_subnet" "untrusted" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.untrusted_subnet_cidr
  availability_zone = var.azs[0]
  tags = {
    Name = "UntrustedSubnet"
  }
}

resource "aws_subnet" "trusted" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.trusted_subnet_cidr
  availability_zone = var.azs[1]
  tags = {
    Name = "TrustedSubnet"
  }
}

# NAT Gateway (Public subnet required)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "MainNAT"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "untrusted" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "untrusted" {
  subnet_id      = aws_subnet.untrusted.id
  route_table_id = aws_route_table.untrusted.id
}

resource "aws_route_table" "trusted" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "trusted" {
  subnet_id      = aws_subnet.trusted.id
  route_table_id = aws_route_table.trusted.id
}

# Security Groups
resource "aws_security_group" "untrusted_workspaces" {
  name        = "untrusted-workspaces"
  description = "Allow RDP from Organization IPs"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.organization_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "trusted_resources" {
  name        = "trusted-resources"
  description = "Allow internal communication"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS Managed Microsoft AD
resource "aws_directory_service_directory" "ad" {
  name     = "corp.example.com"
  password = var.ad_admin_password
  size     = "Small"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = aws_vpc.main.id
    subnet_ids = [aws_subnet.untrusted.id, aws_subnet.trusted.id]
  }
}

# WorkSpaces
resource "aws_workspaces_workspace" "untrusted" {
  count                          = 2
  bundle_id                      = var.workspace_bundle_id
  directory_id                   = aws_directory_service_directory.ad.id
  user_name                      = "user${count.index + 1}@corp.example.com"
  root_volume_encryption_enabled = true
  user_volume_encryption_enabled = true
  subnet_id                      = aws_subnet.untrusted.id
}

resource "aws_workspaces_workspace" "trusted" {
  count                          = 4 # 3 users + 1 application
  bundle_id                      = var.workspace_bundle_id
  directory_id                   = aws_directory_service_directory.ad.id
  user_name                      = count.index < 3 ? "user${count.index + 1}@corp.example.com" : "app@corp.example.com"
  root_volume_encryption_enabled = true
  user_volume_encryption_enabled = true
  subnet_id                      = aws_subnet.trusted.id
}

# RDS MSSQL Instances
resource "aws_db_subnet_group" "trusted" {
  name       = "trusted-db-subnet-group"
  subnet_ids = [aws_subnet.trusted.id]
}

resource "aws_db_instance" "mssql" {
  count                  = 2
  identifier             = "mssql-instance-${count.index}"
  engine                 = "sqlserver-ex"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.rds_username
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.trusted.name
  vpc_security_group_ids = [aws_security_group.trusted_resources.id]
  skip_final_snapshot    = true
}

# RDS Proxy
resource "aws_db_proxy" "mssql_proxy" {
  name                   = "mssql-proxy"
  debug_logging          = false
  engine_family          = "SQLSERVER"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.trusted_resources.id]
  vpc_subnet_ids         = [aws_subnet.trusted.id]

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.rds_credentials.arn
  }
}

resource "aws_db_proxy_target" "mssql" {
  count                  = 2
  db_proxy_name          = aws_db_proxy.mssql_proxy.name
  target_group_name      = "default"
  db_instance_identifier = aws_db_instance.mssql[count.index].id
}
