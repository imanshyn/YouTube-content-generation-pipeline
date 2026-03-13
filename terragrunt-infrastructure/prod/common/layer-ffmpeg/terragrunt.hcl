include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../terraform-modules/lambda-layer"
}

inputs = {
  layer_name      = "${local.env.locals.environment}-ffmpeg"
  build_script    = "${get_terragrunt_dir()}/../../../../apps/mp4_converter_lambda/helpers/build_ffmpeg_layer.sh"
  output_dir      = get_terragrunt_dir()
  output_zip_name = "ffmpeg-layer.zip"
  description     = "FFmpeg static binary for mp4 conversion"

  compatible_runtimes = ["python3.12"]
}
