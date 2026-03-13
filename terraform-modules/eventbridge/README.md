# EventBridge Module

Generic EventBridge rule with a Lambda target. Supports both cron schedules and event pattern triggers (mutually exclusive).

## Resources Created

- `aws_cloudwatch_event_rule` — The EventBridge rule
- `aws_cloudwatch_event_target` — Lambda target with optional input transformer
- `aws_lambda_permission` — Grants EventBridge permission to invoke the Lambda

## Usage

### Cron Schedule

```hcl
module "daily_trigger" {
  source = "../../terraform-modules/eventbridge"

  rule_name           = "prod-daily-mp3-generator"
  description         = "Trigger MP3 generation daily at 6 AM UTC"
  schedule_expression = "cron(0 6 * * ? *)"
  lambda_arn          = module.mp3_generator.function_arn
  lambda_function_name = module.mp3_generator.function_name
  input               = jsonencode({ prompts_bucket = "my-prompts-bucket", topic = "motivation" })
  tags                = { Environment = "production" }
}
```

### Event Pattern (S3 object created)

```hcl
module "on_mp3_created" {
  source = "../../terraform-modules/eventbridge"

  rule_name    = "prod-mp4-converter-on-mp3"
  description  = "Trigger MP4 conversion when .mp3 is uploaded"
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail      = { bucket = { name = ["my-content-bucket"] }, object = { key = [{ suffix = ".mp3" }] } }
  })
  lambda_arn           = module.mp4_converter.function_arn
  lambda_function_name = module.mp4_converter.function_name
  tags                 = { Environment = "production" }
}
```

## Variables

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `rule_name` | string | yes | — | Name of the EventBridge rule |
| `description` | string | no | `""` | Rule description |
| `schedule_expression` | string | no | `null` | Cron/rate expression. Mutually exclusive with `event_pattern` |
| `event_pattern` | string | no | `null` | Event pattern JSON. Mutually exclusive with `schedule_expression` |
| `lambda_arn` | string | yes | — | ARN of the target Lambda |
| `lambda_function_name` | string | yes | — | Name of the target Lambda (for permission resource) |
| `input` | string | no | `null` | Static JSON input passed to the target |
| `input_transformer` | object | no | `null` | Input transformer with `input_paths_map` and `input_template` |
| `enabled` | bool | no | `true` | Whether the rule is enabled |
| `tags` | map(string) | no | `{}` | Tags for all resources |

## Outputs

| Name | Description |
|---|---|
| `rule_arn` | ARN of the EventBridge rule |
| `rule_name` | Name of the EventBridge rule |
