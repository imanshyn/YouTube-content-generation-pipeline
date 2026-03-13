include "root" {
  path = find_in_parent_folders()
}

locals {
  env        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  source_dir = "../../../../apps/youtube_uploader_lambda"
}

dependency "layer_youtube_deps" {
  config_path = "../layer-youtube-deps"

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
  function_name    = "${local.env.locals.environment}-youtube-uploader"
  filename         = "${get_terragrunt_dir()}/lambda.zip"
  source_code_hash = fileexists("${get_terragrunt_dir()}/lambda.zip") ? filebase64sha256("${get_terragrunt_dir()}/lambda.zip") : null
  layer_arns       = [dependency.layer_youtube_deps.outputs.layer_arn]

  iam_policy_statements = [
    {
      Effect   = "Allow"
      Action   = "s3:GetObject"
      Resource = "arn:aws:s3:::${local.env.locals.content_bucket}/*"
    },
    {
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:PutParameter"]
      Resource = [
        "arn:aws:ssm:*:*:parameter/youtube/*/client_id",
        "arn:aws:ssm:*:*:parameter/youtube/*/client_secret",
        "arn:aws:ssm:*:*:parameter/youtube/*/refresh_token"
      ]
    }
  ]

  tags = merge(local.env.locals.common_tags, {
    Component = "youtube-uploader"
  })
}
