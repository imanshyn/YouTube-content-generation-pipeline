# Lambda Function Module

Generic Lambda function with IAM role, inline policy, and CloudWatch log group. CloudWatch Logs permissions are automatically included — only provide additional IAM statements.

## Resources Created

- `aws_lambda_function` — The Lambda function
- `aws_iam_role` — Execution role with assume-role policy for `lambda.amazonaws.com`
- `aws_iam_role_policy` — Inline policy combining provided statements + CloudWatch Logs
- `aws_cloudwatch_log_group` — Log group with configurable retention

## Usage

```hcl
module "mp3_generator" {
  source = "../../terraform-modules/lambda-function"

  function_name    = "prod-mp3-generator"
  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
  memory_size      = 256
  timeout          = 300

  environment_variables = {
    OUTPUT_BUCKET    = "my-content-bucket"
    BEDROCK_MODEL_ID = "us.anthropic.claude-sonnet-4-20250514-v1:0"
  }

  iam_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::my-prompts-bucket/*"]
    }
  ]

  tags = { Environment = "production" }
}
```

## Variables

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `function_name` | string | yes | — | Lambda function name (alphanumeric, hyphens, underscores) |
| `handler` | string | no | `lambda_function.lambda_handler` | Handler entrypoint |
| `runtime` | string | no | `python3.12` | Lambda runtime |
| `timeout` | number | no | `300` | Timeout in seconds (1–900) |
| `memory_size` | number | no | `128` | Memory in MB (128–10240) |
| `filename` | string | yes | — | Path to the deployment zip |
| `source_code_hash` | string | no | `null` | Base64-encoded SHA256 of the zip |
| `layer_arns` | list(string) | no | `[]` | Lambda layer ARNs to attach |
| `iam_policy_statements` | any | yes | — | IAM policy statements (at least one required) |
| `environment_variables` | map(string) | no | `{}` | Environment variables |
| `log_retention_days` | number | no | `14` | CloudWatch log retention (valid values: 1, 3, 5, 7, 14, 30, 60, 90, etc.) |
| `tags` | map(string) | no | `{}` | Tags for all resources |

## Outputs

| Name | Description |
|---|---|
| `function_arn` | ARN of the Lambda function |
| `function_name` | Name of the Lambda function |
| `role_arn` | ARN of the IAM execution role |
