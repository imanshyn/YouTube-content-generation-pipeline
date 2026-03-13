# S3 Lambda Notification Module

Configures S3 bucket notifications to invoke Lambda functions on object events. Supports multiple notification configurations on a single bucket.

## Resources Created

- `aws_lambda_permission` — One per notification, grants S3 permission to invoke the Lambda
- `aws_s3_bucket_notification` — Bucket notification configuration with all Lambda targets

## Usage

```hcl
module "s3_notifications" {
  source = "../../terraform-modules/s3-lambda-notification"

  bucket_name = module.content_bucket.bucket_name
  bucket_arn  = module.content_bucket.bucket_arn

  lambda_notifications = [
    {
      id            = "mp3-to-mp4"
      lambda_arn    = module.mp4_converter.function_arn
      function_name = module.mp4_converter.function_name
      events        = ["s3:ObjectCreated:*"]
      filter_suffix = ".mp3"
    },
    {
      id            = "mp4-to-youtube"
      lambda_arn    = module.youtube_uploader.function_arn
      function_name = module.youtube_uploader.function_name
      events        = ["s3:ObjectCreated:*"]
      filter_suffix = ".mp4"
    }
  ]
}
```

## Variables

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `bucket_name` | string | yes | — | S3 bucket name to attach notifications to |
| `bucket_arn` | string | yes | — | S3 bucket ARN |
| `lambda_notifications` | list(object) | yes | — | List of notification configs (see below) |

### lambda_notifications object

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique identifier for this notification |
| `lambda_arn` | string | yes | ARN of the target Lambda |
| `function_name` | string | yes | Name of the target Lambda (for permission) |
| `events` | list(string) | yes | S3 event types (e.g., `["s3:ObjectCreated:*"]`) |
| `filter_prefix` | string | no | Key prefix filter |
| `filter_suffix` | string | no | Key suffix filter |

## Outputs

| Name | Description |
|---|---|
| `notification_id` | ID of the S3 bucket notification resource |
