terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
}

module "connectivity" {
    source = "../../modules/connectivity"

    vpc_name = var.vpc_name
}

module "accounts" {
    source = "../../modules/accounts"
    depends_on = [module.connectivity]
 
    aws_vpc = module.connectivity.aws_vpc
    subnets_trusted = module.connectivity.aws_subnets_trusted
    dev_users_list = var.dev_users
    guest_users_list = var.guest_users
}

module "workspaces" {
    source = "../../modules/workspaces"
    depends_on = [module.accounts]

    dev_users = module.accounts.dev_users
    guest_users = module.accounts.guest_users
    dev_image_id = var.dev_image_id
    guest_image_id = var.guest_image_id
    subnets_trusted = module.connectivity.aws_subnets_trusted
    aws_security_group_workspaces_qq = module.connectivity.aws_security_group_workspaces_qq
    aws_directory_service_directory = module.accounts.aws_directory_service_directory
}
