variable "bucket_name" {
  description = "S3 bucket name to attach notifications to"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "lambda_notifications" {
  description = "List of S3→Lambda notification configurations"
  type = list(object({
    id            = string
    lambda_arn    = string
    function_name = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
}
