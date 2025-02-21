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
