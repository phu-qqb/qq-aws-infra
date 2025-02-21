output "registration_code" {
  value = module.workspaces.registration_code
}

output "dev_users" {
  value = module.accounts.dev_users
  sensitive = true
}

output "guest_users" {
  value = module.accounts.guest_users
  sensitive = true
}

output "app_users" {
  value = module.accounts.app_users
  sensitive = true
}
