include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "mp3_generator" {
  config_path = "../../common/mp3-generator"

  mock_outputs = {
    function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:mock"
    function_name = "mock"
  }
}

terraform {
  source = "../../../../terraform-modules/eventbridge"
}

inputs = {
  rule_name            = "${local.env.locals.environment}-${local.env.locals.topic}-mp3-generator-daily"
  description          = "Triggers mp3 generator daily for ${local.env.locals.topic} topic"
  schedule_expression  = "cron(0 6 * * ? *)"
  lambda_arn           = dependency.mp3_generator.outputs.function_arn
  lambda_function_name = dependency.mp3_generator.outputs.function_name

  input = jsonencode({
    prompts_bucket = local.env.locals.prompts_bucket
    topic          = local.env.locals.topic
    voice          = "Ruth"
  })

  tags = merge(local.env.locals.common_tags, {
    Component = "eventbridge-mp3"
  })
}
