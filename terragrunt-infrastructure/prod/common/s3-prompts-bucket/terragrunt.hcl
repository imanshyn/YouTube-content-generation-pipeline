include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../terraform-modules/s3-bucket"
}

inputs = {
  bucket_name = local.env.locals.prompts_bucket

  tags = merge(local.env.locals.common_tags, {
    Component = "prompts-bucket"
  })
}
