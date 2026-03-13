output "layer_arn" {
  value = aws_lambda_layer_version.this.arn
}

output "layer_version" {
  value = aws_lambda_layer_version.this.version
}
