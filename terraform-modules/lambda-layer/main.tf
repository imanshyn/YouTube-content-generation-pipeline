resource "null_resource" "build" {
  triggers = {
    build_script = filesha256(var.build_script)
    force_rebuild = var.force_rebuild ? timestamp() : "static"
  }

  provisioner "local-exec" {
    command     = "bash ${var.build_script} ${var.output_dir}"
    working_dir = dirname(var.build_script)
  }
}

resource "aws_lambda_layer_version" "this" {
  layer_name          = var.layer_name
  filename            = "${var.output_dir}/${var.output_zip_name}"
  source_code_hash    = null_resource.build.id
  compatible_runtimes = var.compatible_runtimes
  description         = var.description

  depends_on = [null_resource.build]
}
