# S3 Bucket Module

Creates an S3 bucket with versioning, KMS server-side encryption, and all public access blocked.

## Resources Created

- `aws_s3_bucket` — The bucket
- `aws_s3_bucket_versioning` — Versioning enabled
- `aws_s3_bucket_server_side_encryption_configuration` — SSE with `aws:kms`
- `aws_s3_bucket_public_access_block` — All 4 public access flags blocked

## Usage

```hcl
module "content_bucket" {
  source = "../../terraform-modules/s3-bucket"

  bucket_name = "video-generator-content-bucket"
  tags        = { Environment = "production" }
}
```

## Variables

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `bucket_name` | string | yes | — | Name of the S3 bucket |
| `tags` | map(string) | no | `{}` | Tags for all resources |

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Name (ID) of the S3 bucket |
| `bucket_arn` | ARN of the S3 bucket |
