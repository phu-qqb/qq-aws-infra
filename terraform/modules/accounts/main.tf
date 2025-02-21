resource "random_password" "user_passwords" {
  count = length(var.dev_users_list)
  length  = 16
  special = true
}

locals {
  domain_name = var.domain_name
  max_retry_attempts = 100
  retry_sleep_seconds = 3
  dev_users = {
    for user in var.dev_users_list:
    user => {name = user, password = random_password.user_passwords[index(var.dev_users_list, user)].result}
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

resource "null_resource" "ds-data-enable-access" {
  provisioner "local-exec" {
    command = "aws ds enable-directory-data-access --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id}"
  }
  depends_on = [aws_directory_service_directory.dir_workspaces_qq]
}

resource "null_resource" "ad_add_group_command" {
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, local.ad_add_group_command)
    interpreter = local.interpreter
  }

  depends_on = [null_resource.ds-data-enable-access]

  triggers = {
    dummy = var.retry_sleep_seconds
    timestamp    = timestamp()
  }
}

resource "null_resource" "ds-data-add-to-domain-users" {
  for_each = local.dev_users
  provisioner "local-exec" {
    command = "aws ds-data create-user --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id}  --sam-account-name ${each.value.name}"
  }
  provisioner "local-exec" {
    command = "aws ds reset-user-password --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --user-name ${each.value.name} --new-password ${each.value.password}"
  }
  depends_on = [null_resource.ad_add_group_command]
}

resource "null_resource" "ad_check_user_command" {
  provisioner "local-exec" {
    command     = format(local.is_windows ? local.powershell_script : local.bash_script, local.ad_check_user_command)
    interpreter = local.interpreter
  }

  depends_on = [null_resource.ds-data-add-to-domain-users]

  triggers = {
    dummy = var.retry_sleep_seconds
    timestamp    = timestamp()
  }
}

locals {
  # Determine OS-specific interpreter and commands
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  
  interpreter = local.is_windows ? ["powershell", "-Command"] : ["bash", "-c"]

  ad_add_group_command = "aws ds-data create-group --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id} --sam-account-name test-group --group-scope DomainLocal"
  ad_check_user_command = "aws ds-data describe-user --directory-id ${aws_directory_service_directory.dir_workspaces_qq.id}  --sam-account-name dev-dev-dev"
  
  # OS-specific script content
  powershell_script = <<EOF
    $maxAttempts = ${var.max_retry_attempts}
    $sleepTime = ${var.retry_sleep_seconds}
    $attempt = 1

    do {
        Write-Host "Attempt $attempt of $maxAttempts"
        try {
            # Run your AWS command here
            %s 2>&1
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
    max_attempts=${var.max_retry_attempts}
    sleep_time=${var.retry_sleep_seconds}
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
}
