include "root" {
  path = find_in_parent_folders()
}

locals {
  env        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  source_dir = "../../../../apps/mp4_converter_lambda"
}

dependency "layer_ffmpeg" {
  config_path = "../layer-ffmpeg"

  mock_outputs = {
    layer_arn = "arn:aws:lambda:us-east-1:123456789012:layer:mock:1"
  }
}

terraform {
  source = "../../../../terraform-modules/lambda-function"

  before_hook "package" {
    commands = ["apply", "plan"]
    execute  = ["bash", "-c", "cd ${get_terragrunt_dir()}/${local.source_dir} && zip -r ${get_terragrunt_dir()}/lambda.zip lambda_function.py"]
  }
}

inputs = {
  function_name    = "${local.env.locals.environment}-mp4-converter"
  filename         = "${get_terragrunt_dir()}/lambda.zip"
  source_code_hash = fileexists("${get_terragrunt_dir()}/lambda.zip") ? filebase64sha256("${get_terragrunt_dir()}/lambda.zip") : null
  layer_arns       = [dependency.layer_ffmpeg.outputs.layer_arn]
  timeout          = 900
  memory_size      = 4096

  iam_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:HeadObject", "s3:PutObject"]
      Resource = "arn:aws:s3:::${local.env.locals.content_bucket}/*"
    },
    {
      Effect   = "Allow"
      Action   = "s3:ListBucket"
      Resource = "arn:aws:s3:::${local.env.locals.content_bucket}"
    }
  ]

  tags = merge(local.env.locals.common_tags, {
    Component = "mp4-converter"
  })
}
