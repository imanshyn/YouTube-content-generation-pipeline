include "root" {
  path = find_in_parent_folders()
}

locals {
  env        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  source_dir = "../../../../apps/mp3_generator_lambda"
}

terraform {
  source = "../../../../terraform-modules/lambda-function"

  before_hook "package" {
    commands = ["apply", "plan"]
    execute  = ["bash", "-c", "cd ${get_terragrunt_dir()}/${local.source_dir} && zip -r ${get_terragrunt_dir()}/lambda.zip lambda_function.py"]
  }
}

inputs = {
  function_name    = "${local.env.locals.environment}-mp3-generator"
  filename         = "${get_terragrunt_dir()}/lambda.zip"
  source_code_hash = fileexists("${get_terragrunt_dir()}/lambda.zip") ? filebase64sha256("${get_terragrunt_dir()}/lambda.zip") : null

  iam_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["s3:ListBucket", "s3:GetObject"]
      Resource = [
        "arn:aws:s3:::${local.env.locals.prompts_bucket}",
        "arn:aws:s3:::${local.env.locals.prompts_bucket}/*"
      ]
    },
    {
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "arn:aws:s3:::${local.env.locals.content_bucket}/*"
    },
    {
      Effect   = "Allow"
      Action   = "bedrock:InvokeModel"
      Resource = [
        "arn:aws:bedrock:*::foundation-model/*",
        "arn:aws:bedrock:*:*:inference-profile/*"
      ]
    },
    {
      Effect   = "Allow"
      Action   = "polly:StartSpeechSynthesisTask"
      Resource = "*"
    }
  ]

  environment_variables = {
    OUTPUT_BUCKET    = local.env.locals.content_bucket
    BEDROCK_MODEL_ID = "us.anthropic.claude-sonnet-4-20250514-v1:0"
  }

  tags = merge(local.env.locals.common_tags, {
    Component = "mp3-generator"
  })
}
