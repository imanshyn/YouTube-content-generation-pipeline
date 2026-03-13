locals {
  environment    = "prod"
  content_bucket = "video-generator-content-bucket"
  prompts_bucket = "video-generator-prompts-bucket"

  common_tags = {
    Environment = "production"
    ManagedBy   = "terragrunt"
  }
}
