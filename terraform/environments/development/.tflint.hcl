config {
  call_module_type    = "all"
  force               = true
  disabled_by_default = false
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

rule "terraform_unused_declarations" {
  enabled = false
}
