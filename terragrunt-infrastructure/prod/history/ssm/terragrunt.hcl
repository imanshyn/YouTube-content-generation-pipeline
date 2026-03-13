include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../terraform-modules/ssm-parameter"
}

inputs = {
  parameters = [
    {
      name  = "/youtube/${local.env.locals.topic}/client_id"
      type  = "SecureString"
      value = "CHANGE_ME"
    },
    {
      name  = "/youtube/${local.env.locals.topic}/client_secret"
      type  = "SecureString"
      value = "CHANGE_ME"
    },
    {
      name  = "/youtube/${local.env.locals.topic}/refresh_token"
      type  = "SecureString"
      value = "CHANGE_ME"
    }
  ]

  tags = merge(local.env.locals.common_tags, {
    Component = "ssm"
  })
}
