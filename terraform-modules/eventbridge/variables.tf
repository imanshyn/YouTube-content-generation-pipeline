variable "rule_name" {
  description = "Name of the EventBridge rule"
  type        = string
}

variable "description" {
  description = "Description of the rule"
  type        = string
  default     = ""
}

variable "schedule_expression" {
  description = "Schedule expression (cron/rate). Mutually exclusive with event_pattern"
  type        = string
  default     = null
}

variable "event_pattern" {
  description = "Event pattern JSON. Mutually exclusive with schedule_expression"
  type        = string
  default     = null
}

variable "lambda_arn" {
  description = "ARN of the target Lambda function"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the target Lambda function (for permission)"
  type        = string
}

variable "input" {
  description = "Static JSON input to pass to the target"
  type        = string
  default     = null
}

variable "input_transformer" {
  description = "Input transformer configuration"
  type = object({
    input_paths_map = map(string)
    input_template  = string
  })
  default = null
}

variable "enabled" {
  description = "Whether the rule is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
