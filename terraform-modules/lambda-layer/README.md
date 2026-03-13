# Lambda Layer Module

Builds and publishes a Lambda layer by executing a build script via `null_resource` local-exec, then creating the layer version from the resulting zip.

## Resources Created

- `null_resource` — Runs the build script (re-triggers when script content changes)
- `aws_lambda_layer_version` — The published layer version

## Usage

```hcl
module "ffmpeg_layer" {
  source = "../../terraform-modules/lambda-layer"

  layer_name     = "ffmpeg"
  build_script   = "${path.module}/../../apps/mp4_converter_lambda/helpers/build_ffmpeg_layer.sh"
  output_dir     = "${path.module}/../../apps/mp4_converter_lambda/helpers"
  output_zip_name = "ffmpeg-layer.zip"

  compatible_runtimes = ["python3.12"]
  description         = "ffmpeg binary for video conversion"
}
```

## Variables

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `layer_name` | string | yes | — | Name of the Lambda layer |
| `build_script` | string | yes | — | Absolute path to the build script that produces the zip |
| `output_dir` | string | yes | — | Directory where the build script outputs the zip |
| `output_zip_name` | string | yes | — | Name of the zip file produced by the build script |
| `compatible_runtimes` | list(string) | no | `["python3.12"]` | Compatible Lambda runtimes |
| `description` | string | no | `""` | Layer description |
| `force_rebuild` | bool | no | `false` | Set to `true` to force rebuild on every apply |

## Outputs

| Name | Description |
|---|---|
| `layer_arn` | ARN of the published layer version |
| `layer_version` | Version number of the published layer |

## Build Trigger

The layer rebuilds when the build script's content hash changes. Set `force_rebuild = true` to rebuild on every `terraform apply` regardless.
