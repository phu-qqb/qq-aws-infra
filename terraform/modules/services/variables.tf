variable "rds_instances" {
  type = map(object({
    identifier = string
    class      = string
    storage    = number
  }))
  default = {
    prod = {
      identifier = "rds-prod-qq"
      class      = "db.t3.xlarge"
      storage    = 20
    }
    qa = {
      identifier = "rds-qa-qq"
      class      = "db.t3.xlarge"
      storage    = 20
    }
  }
}

variable "rds_proxy_name" {
  type = string
  default = "rds-proxy-qq"
}

variable "subnets_trusted" {}
variable "aws_vpc" {}
