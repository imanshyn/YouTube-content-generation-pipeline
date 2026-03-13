data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "this" {
  for_each = { for n in var.lambda_notifications : n.id => n }

  statement_id  = "AllowS3-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket_notification" "this" {
  bucket = var.bucket_name

  dynamic "lambda_function" {
    for_each = var.lambda_notifications
    content {
      id                  = lambda_function.value.id
      lambda_function_arn = lambda_function.value.lambda_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  depends_on = [aws_lambda_permission.this]
}
