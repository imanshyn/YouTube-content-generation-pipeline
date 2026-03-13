variable "function_name" {
  description = "Lambda function name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "function_name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"

  validation {
    condition     = can(regex("^(python|nodejs|java|dotnet|ruby|go)", var.runtime))
    error_message = "runtime must be a valid Lambda runtime (e.g. python3.12, nodejs20.x)."
  }
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "filename" {
  description = "Path to the Lambda deployment package"
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package"
  type        = string
  default     = null
}

variable "layer_arns" {
  description = "Lambda layer ARNs to attach"
  type        = list(string)
  default     = []
}

variable "iam_policy_statements" {
  description = "List of IAM policy statements for the Lambda execution role (beyond CloudWatch Logs, which is always included)"
  type        = any

  validation {
    condition     = length(var.iam_policy_statements) > 0
    error_message = "At least one IAM policy statement must be provided."
  }
}

variable "environment_variables" {
  description = "Environment variables for the Lambda"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
