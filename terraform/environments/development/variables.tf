variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "untrusted_subnet_cidr" {
  description = "CIDR block for the untrusted subnet"
  default     = "10.0.1.0/24"
}

variable "trusted_subnet_cidr" {
  description = "CIDR block for the trusted subnet"
  default     = "10.0.2.0/24"
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "workspace_bundle_id" {
  description = "AWS WorkSpaces Windows bundle ID"
  default     = "wsb-12345678" # Replace with valid bundle ID
}

variable "organization_ips" {
  description = "Allowed IPs for WorkSpaces access"
  type        = list(string)
  default     = ["123.45.67.89/32"]
}

variable "rds_username" {
  description = "RDS master username"
  default     = "admin"
}

variable "rds_password" {
  description = "RDS master password"
  sensitive   = true
}

variable "ad_admin_password" {
  description = "Active Directory admin password"
  sensitive   = true
}
