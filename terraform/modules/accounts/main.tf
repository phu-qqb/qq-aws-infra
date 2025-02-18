terraform {
  required_version = "~> 1.8"
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