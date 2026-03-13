# SSM Parameter Module

Creates multiple SSM parameters with `ignore_changes = [value]` lifecycle, allowing initial creation via Terraform while managing values out-of-band (e.g., manually or via CI/CD).

## Resources Created

- `aws_ssm_parameter` — One per parameter entry (via `for_each`)

## Usage

```hcl
module "youtube_creds" {
  source = "../../terraform-modules/ssm-parameter"

  parameters = [
    { name = "/youtube/history/client_id",     type = "SecureString", value = "CHANGE_ME" },
    { name = "/youtube/history/client_secret",  type = "SecureString", value = "CHANGE_ME" },
    { name = "/youtube/history/refresh_token",  type = "SecureString", value = "CHANGE_ME" },
  ]

  tags = { Environment = "production" }
}
```

After `terraform apply`, update the actual values out-of-band:

```bash
aws ssm put-parameter --name /youtube/history/client_id --value "<client_id>" --type SecureString --overwrite
```

Terraform will not overwrite manually-set values on subsequent applies.

## Variables

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `parameters` | list(object) | yes | — | List of parameters (see below) |
| `tags` | map(string) | no | `{}` | Tags for all resources |

### parameters object

| Field | Type | Description |
|---|---|---|
| `name` | string | Full SSM parameter path (e.g., `/youtube/history/client_id`) |
| `type` | string | Parameter type: `String`, `StringList`, or `SecureString` |
| `value` | string | Initial value (use placeholder like `CHANGE_ME`) |

## Outputs

| Name | Description |
|---|---|
| `parameter_arns` | Map of parameter name → ARN |
| `parameter_names` | Map of parameter name → full name path |
