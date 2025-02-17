variable "domain_name" {
  default = "quantumqb.corp"
}

variable "user_list" {
  type = list(string)
  description = "List of users in email format"
  default = [
    "dev1@dev.quantumqb.corp",
    # "dev2@dev.quantumqb.corp",
    # "dev3@dev.quantumqb.corp",
    # "user1@user.quantumqb.corp",
    # "user2@user.quantumqb.corp"
  ]
}