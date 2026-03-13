variable "layer_name" {
  description = "Name of the Lambda layer"
  type        = string
}

variable "build_script" {
  description = "Absolute path to the build script that produces the layer zip"
  type        = string
}

variable "output_dir" {
  description = "Directory where the build script outputs the zip"
  type        = string
}

variable "output_zip_name" {
  description = "Name of the zip file produced by the build script"
  type        = string
}

variable "compatible_runtimes" {
  description = "List of compatible Lambda runtimes"
  type        = list(string)
  default     = ["python3.12"]
}

variable "description" {
  description = "Description of the Lambda layer"
  type        = string
  default     = ""
}

variable "force_rebuild" {
  description = "Set to true to force a rebuild on every apply"
  type        = bool
  default     = false
}
