variable "region" {
  default = "eu-west-2"
}

variable "vpc_name" {
  type = string
  default = "development"
}

variable "domain_name" {
  type = string
  default = "development.workspaces.qq"
}

variable "dev_users" {
  type = list(string)
  # default = ["dev-user-1", "dev-user-2", "dev-user-3"]
  default = ["dev-user-1"]
}

variable "dev_image_id" {
  type = string
  default = "wsb-6cbvhvv9f"
}

variable "guest_users" {
  type = list(string)
  # default = ["guest-user-1", "guest-user-2", "guest-user-3"]
  default = ["guest-user-1"]
}

variable "guest_image_id" {
  type = string
  default = "wsb-6cbvhvv9f"
}

variable "app_image_id" {
  type = string
  default = "wsb-6cbvhvv9f"
}