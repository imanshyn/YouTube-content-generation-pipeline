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
  layer_name      = "${local.env.locals.environment}-youtube-deps"
  build_script    = "${get_terragrunt_dir()}/../../../../apps/youtube_uploader_lambda/helpers/build_layer.sh"
  output_dir      = get_terragrunt_dir()
  output_zip_name = "layer.zip"
  description     = "Google API Python dependencies for YouTube uploader"

  compatible_runtimes = ["python3.12"]
}
