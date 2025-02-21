output "aws_directory_service_directory" {
  value = aws_directory_service_directory.dir_workspaces_qq
}

output "app_users" {
  value = local.app_users
  sensitive = true
}

output "guest_users" {
  value = local.guest_users
  sensitive = true
}

output "dev_users" {
  value = local.dev_users
  sensitive = true
}
