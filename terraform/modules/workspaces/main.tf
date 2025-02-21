# Workspace Directory
resource "aws_workspaces_directory" "wsdir_qq" {
  directory_id = var.aws_directory_service_directory.id
  subnet_ids   = [for subnet in var.subnets_trusted : subnet.id]

  workspace_creation_properties {
    custom_security_group_id            = var.aws_security_group_workspaces_qq.id
    default_ou                          = "OU=Users,OU=workspaces,DC=workspaces,DC=qq,DC=com"
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
    running_mode_auto_stop_timeout_minutes    = 30
  }
}

resource "aws_workspaces_workspace" "appstation" {
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
}
