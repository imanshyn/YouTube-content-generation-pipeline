variable "parameters" {
  description = "List of SSM parameters to create"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
