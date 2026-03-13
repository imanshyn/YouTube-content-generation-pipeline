include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "s3_content_bucket" {
  config_path = "../../common/s3-content-bucket"

  mock_outputs = {
    bucket_name = "mock-bucket"
    bucket_arn  = "arn:aws:s3:::mock-bucket"
  }
}

dependency "mp4_converter" {
  config_path = "../../common/mp4-converter"

  mock_outputs = {
    function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:mock"
    function_name = "mock"
  }
}

dependency "youtube_uploader" {
  config_path = "../../common/youtube-uploader"

  mock_outputs = {
    function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:mock"
    function_name = "mock"
  }
}

terraform {
  source = "../../../../terraform-modules/s3-lambda-notification"
}

inputs = {
  bucket_name = dependency.s3_content_bucket.outputs.bucket_name
  bucket_arn  = dependency.s3_content_bucket.outputs.bucket_arn

  lambda_notifications = [
    {
      id            = "${local.env.locals.topic}-mp4-converter-on-mp3"
      lambda_arn    = dependency.mp4_converter.outputs.function_arn
      function_name = dependency.mp4_converter.outputs.function_name
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "${local.env.locals.topic}/"
      filter_suffix = ".mp3"
    },
    {
      id            = "${local.env.locals.topic}-youtube-uploader-on-mp4"
      lambda_arn    = dependency.youtube_uploader.outputs.function_arn
      function_name = dependency.youtube_uploader.outputs.function_name
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "${local.env.locals.topic}/"
      filter_suffix = ".mp4"
    }
  ]

  tags = merge(local.env.locals.common_tags, {
    Component = "s3-notifications"
  })
}
