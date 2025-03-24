output "registration_code" {
  value = nonsensitive(module.workspaces.registration_code)
}

# output "dev_users" {
#   value = nonsensitive(module.accounts.dev_users)
#   # sensitive = true
# }

# output "guest_users" {
#   value = nonsensitive(module.accounts.guest_users)
#   # sensitive = true
# }

# output "app_users" {
#   value = nonsensitive(module.accounts.app_users)
#   # sensitive = true
# }
