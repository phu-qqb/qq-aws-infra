resource "random_password" "user_passwords" {
  count = length(var.dev_users_list)
  length  = 16
  special = true
}

locals {
  domain_name = var.domain_name
  max_retry_attempts = 100
  retry_sleep_seconds = 2
  dev_users = {
    for user in var.dev_users_list:
    user => {name = user, password = random_password.user_passwords[index(var.dev_users_list, user)].result}
  }
  guest_users = {
    for user in var.guest_users_list:
    user => {name = user, password = random_password.user_passwords[index(var.guest_users_list, user)].result}
  }
  app_users_list = ["app_dev"]
  app_users = {
    for user in local.app_users_list:
    user => {name = user, password = random_password.user_passwords[index(local.app_users_list, user)].result}
  }
}

resource "aws_directory_service_directory" "dir_workspaces_qq" {
  name     = local.domain_name
  password = "chah8_Pre"
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = var.aws_vpc.id
    subnet_ids = [for subnet in var.subnets_trusted : subnet.id]
  }

  tags = {
    Name = "dir-workspaces-qq"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {

  domain_name_servers = aws_directory_service_directory.dir_workspaces_qq.dns_ip_addresses
  domain_name = "development.workspaces.qq"

  tags = {
    Name = "Workspaces"
    Environment = "Domain for Workspaces"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id = var.aws_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

resource "null_resource" "ds-data-enable-access" {
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, local.ad_enable_management_command)
    interpreter = local.interpreter
  }

  depends_on = [aws_directory_service_directory.dir_workspaces_qq]
  triggers = {
    timestamp    = timestamp()
  }
}

resource "null_resource" "ad_add_user_group_command" {
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, local.ad_add_user_group_command)
    interpreter = local.interpreter
  }

  depends_on = [null_resource.ds-data-enable-access]
  triggers = {
    timestamp    = timestamp()
  }
}

resource "null_resource" "ad_add_dev_group_command" {
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, local.ad_add_dev_group_command)
    interpreter = local.interpreter
  }

  depends_on = [null_resource.ds-data-enable-access]
  triggers = {
    timestamp    = timestamp()
  }
}

resource "null_resource" "ds-data-add-to-guest-users" {
  for_each = local.dev_users
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, format(local.ad_add_user_command, each.value.name))
    interpreter = local.interpreter
  }
  provisioner "local-exec" {
    command = "aws ds reset-user-password --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --user-name ${each.value.name} --new-password \"${each.value.password}\""
    interpreter = local.interpreter
  }
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, format(local.ad_add_user_to_group_command, "UserGuestQQ", each.value.name))
    interpreter = local.interpreter
  }
  depends_on = [null_resource.ad_add_user_group_command]
  triggers = {
    timestamp    = timestamp()
  }
}

resource "null_resource" "ds-data-add-to-dev-users" {
  for_each = local.guest_users
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, format(local.ad_add_user_command, each.value.name))
    interpreter = local.interpreter
  }
  provisioner "local-exec" {
    command = "aws ds reset-user-password --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --user-name ${each.value.name} --new-password \"${each.value.password}\""
    interpreter = local.interpreter
  }
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, format(local.ad_add_user_to_group_command, "UserDevQQ", each.value.name))
    interpreter = local.interpreter
  }
  depends_on = [null_resource.ad_add_dev_group_command]
    triggers = {
    timestamp    = timestamp()
  }
}

resource "null_resource" "ds-data-add-to-app-users" {
  for_each = local.app_users
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, format(local.ad_add_user_command, each.value.name))
    interpreter = local.interpreter
  }
  provisioner "local-exec" {
    command = "aws ds reset-user-password --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --user-name ${each.value.name} --new-password \"${each.value.password}\""
    interpreter = local.interpreter
  }
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, format(local.ad_add_user_to_group_command, "UserDevQQ", each.value.name))
    interpreter = local.interpreter
  }
  depends_on = [null_resource.ad_add_dev_group_command]
    triggers = {
    timestamp    = timestamp()
  }
}


resource "null_resource" "ad_check_user_command" {
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, local.ad_check_user_command)
    interpreter = local.interpreter
  }

  depends_on = [null_resource.ds-data-add-to-dev-users, null_resource.ds-data-add-to-guest-users]

  triggers = {
    timestamp    = timestamp()
  }
}

locals {
  # Determine OS-specific interpreter and commands
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  
  interpreter = local.is_windows ? ["pwsh", "-Command"] : ["bash", "-c"]

  ad_enable_management_command = "aws ds enable-directory-data-access --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id}"
  ad_add_user_group_command = "aws ds-data create-group --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --sam-account-name UserDevQQ --group-scope DomainLocal"
  ad_add_dev_group_command = "aws ds-data create-group --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --sam-account-name UserGuestQQ --group-scope DomainLocal"
  ad_check_user_command = "aws ds-data describe-user --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id}  --sam-account-name ${var.dev_users_list[0]}"
  
  # OS-specific script content
  powershell_script = <<EOF
    $maxAttempts = ${local.max_retry_attempts}
    $sleepTime = ${local.retry_sleep_seconds}
    $attempt = 1

    do {
        Write-Host "Attempt $attempt of $maxAttempts"
        $ErrorActionPreference = 'Continue'
        try {
            $result = %s 2>&1
            if ($result -match "Group already exists in directory") {
              Write-Host "Group has already been created, skipping"
              exit 0
            }
            if ($result -match "is already in the desired state") {
              Write-Host "Management has already been created, skipping"
              exit 0
            }
            if ($result -match "User already exists in directory") {
              Write-Host "User has already been created, skipping"
              exit 0
            }
            # If no error was thrown, command succeeded
            Write-Host "Command succeeded"
            exit 0
        }
        catch {
            Write-Host "Error occurred: $_"
            if ($attempt -eq $maxAttempts) { 
                Write-Host "Max attempts reached"
                exit 1 
            }
            Write-Host "Retrying in $sleepTime seconds..."
            Start-Sleep -Seconds $sleepTime
            $attempt++
        }
    } while ($true)
  EOF

  bash_script = <<EOF
    #!/bin/bash
    max_attempts=${local.max_retry_attempts}
    sleep_time=${local.retry_sleep_seconds}
    attempt=1

    while true; do
      echo "Attempt $attempt of $max_attempts"
      
      if %s 2>/dev/null; then
        echo "Command succeeded"
        exit 0
      else
        error_code=$?
        echo "Command failed with exit code $error_code"
        
        if [ $attempt -eq $max_attempts ]; then
          echo "Max attempts reached"
          exit 1
        fi
        
        echo "Retrying in $sleep_time seconds..."
        sleep $sleep_time
        attempt=$((attempt + 1))
      fi
    done
  EOF

  ad_add_user_command = "aws ds-data create-user --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id}  --sam-account-name %s"
  ad_add_user_to_group_command = "aws ds-data add-group-member --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --group-name %s --member-name %s"
}
