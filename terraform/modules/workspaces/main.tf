# Workspace Directory
resource "aws_workspaces_ip_group" "main" {
  name        = "workspace-ip-group"

  rules {
    source      = "0.0.0.0/0"
    description = "test IP"
  }

  tags = {
    Environment = "Development"
  }
}

resource "aws_workspaces_directory" "wsdir_qq" {
  directory_id = var.aws_directory_service_directory.id
  subnet_ids   = [for subnet in var.subnets_trusted : subnet.id]
  ip_group_ids = [aws_workspaces_ip_group.main.id]

  workspace_creation_properties {
    custom_security_group_id            = var.aws_security_group_workspaces_qq.id
    default_ou                          = "OU=Users,OU=development,DC=development,DC=workspaces,DC=qq"
    enable_internet_access              = false
    enable_maintenance_mode             = false
    user_enabled_as_local_administrator = true
  }
}


data "aws_workspaces_directory" "wsdir_qq" {
  directory_id = aws_workspaces_directory.wsdir_qq.id  

}

resource "aws_workspaces_workspace" "devstation" {
  for_each = var.dev_users
  directory_id = var.aws_directory_service_directory.id
  bundle_id    = var.dev_image_id
  user_name    = each.value.name

  root_volume_encryption_enabled = false
  user_volume_encryption_enabled = false

  workspace_properties {
    compute_type_name                         = "STANDARD"
    # user_volume_size_gib                      = 50
    # root_volume_size_gib                      = 80
    running_mode                              = "ALWAYS_ON"
  }
  depends_on = [aws_workspaces_directory.wsdir_qq]
  timeouts {
    create = "60m"
    delete = "15m"
  }
}

resource "aws_workspaces_workspace" "gueststation" {
  for_each = var.guest_users
  directory_id = var.aws_directory_service_directory.id
  bundle_id    = var.guest_image_id
  user_name    = each.value.name

  root_volume_encryption_enabled = false
  user_volume_encryption_enabled = false

  workspace_properties {  
    compute_type_name                         = "STANDARD"
    # user_volume_size_gib                      = 50
    # root_volume_size_gib                      = 80
    running_mode                              = "AUTO_STOP"
    running_mode_auto_stop_timeout_in_minutes    = 60
  }
  depends_on = [aws_workspaces_directory.wsdir_qq]
  timeouts {
    create = "60m"
    delete = "15m"
  }
}

resource "aws_workspaces_workspace" "appstation" {
  for_each = var.app_users
  directory_id = var.aws_directory_service_directory.id
  bundle_id    = var.app_image_id
  user_name    = each.value.name

  root_volume_encryption_enabled = false
  user_volume_encryption_enabled = false

  workspace_properties {
    compute_type_name                         = "STANDARD"
    # user_volume_size_gib                      = 50
    # root_volume_size_gib                      = 80
    running_mode                              = "ALWAYS_ON"
  }
  depends_on = [aws_workspaces_directory.wsdir_qq]
  timeouts {
    create = "60m"
    delete = "15m"
  }
}
