resource "aws_instance" "gpu_srv_qq" {
  ami           = "ami-00710ab5544b60cf7"
  instance_type = "t2.micro"
  subnet_id     = var.subnets_trusted[0].id

  tags = {
    Name = "gpu-srv-qq"
  }
}

# Secrets Manager for RDS credentials
resource "random_password" "rds_passwords" {
  for_each = var.rds_instances

  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  for_each = var.rds_instances
  
  name = "rds-credentials-${each.key}-qq"
  
  tags = {
    Environment = each.key
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  for_each = var.rds_instances

  secret_id = aws_secretsmanager_secret.rds_credentials[each.key].id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rds_passwords[each.key].result
    engine   = "sqlserver-se"
    # host     = aws_db_instance.rds_instances[each.key].endpoint
    port     = 1433
    dbname   = "master"
  })
}

# IAM role for RDS Proxy
resource "aws_iam_role" "rds_proxy_role" {
  name = "rds-proxy-role-qq"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_proxy_policy" {
  name = "rds-proxy-policy-qq"
  role = aws_iam_role.rds_proxy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [for secret in aws_secretsmanager_secret.rds_credentials : secret.arn]
      }
    ]
  })
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = var.subnets_trusted[*].id

  tags = {
    Name = "My DB subnet group"
  }
}

# RDS Instances with updated configuration
resource "aws_db_instance" "rds_instances" {
  for_each = var.rds_instances

  identifier           = each.value.identifier
  engine              = "sqlserver-se"
  license_model        = "license-included"
  engine_version      = "15.00"
  instance_class      = each.value.class
  allocated_storage   = each.value.storage
  storage_encrypted   = true
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  username = jsondecode(aws_secretsmanager_secret_version.rds_credentials[each.key].secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.rds_credentials[each.key].secret_string)["password"]
}

# RDS Proxies - one for each instance
resource "aws_db_proxy" "rds_proxies" {
  for_each = var.rds_instances

  name                   = "rdsproxy-${each.key}-qq"
  debug_logging         = false
  engine_family         = "SQLSERVER"
  idle_client_timeout   = 1800
  require_tls           = true
  role_arn             = aws_iam_role.rds_proxy_role.arn
  vpc_security_group_ids = [aws_security_group.rds_proxy_sg.id]
  vpc_subnet_ids        = var.subnets_trusted[*].id

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_secretsmanager_secret.rds_credentials[each.key].arn
  }

  tags = {
    Environment = each.key
  }
}

# RDS Proxy Target Groups
resource "aws_db_proxy_default_target_group" "rds_proxy_targets" {
  for_each = var.rds_instances

  db_proxy_name = aws_db_proxy.rds_proxies[each.key].name

  connection_pool_config {
    max_connections_percent = 100
  }
}

# RDS Proxy Target Registrations
resource "aws_db_proxy_target" "rds_proxy_targets" {
  for_each = var.rds_instances

  db_proxy_name          = aws_db_proxy.rds_proxies[each.key].name
  target_group_name      = aws_db_proxy_default_target_group.rds_proxy_targets[each.key].name
  db_instance_identifier = aws_db_instance.rds_instances[each.key].identifier
}

# Security group for RDS instances
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-qq"
  description = "Security group for RDS instances"
  vpc_id      = var.aws_vpc.id

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_proxy_sg.id]
  }
}

# Security group for RDS Proxies
resource "aws_security_group" "rds_proxy_sg" {
  name        = "rds-proxy-sg-qq"
  description = "Security group for RDS Proxies"
  vpc_id      = var.aws_vpc.id

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
