output "aws_directory_service_directory" {
  value = aws_directory_service_directory.dir_workspaces_qq
}

output "app_users" {
  value = nonsensitive(local.app_users)
}

output "guest_users" {
  value = nonsensitive(local.guest_users)
}

output "dev_users" {
  value = nonsensitive(local.dev_users)
}
