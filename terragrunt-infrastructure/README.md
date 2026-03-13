# Terragrunt Infrastructure

IaC orchestration layer for the automated content generation pipeline. Uses Terragrunt to wrap reusable Terraform modules with DRY configuration, dependency management, and per-module state isolation.

## Architecture Overview

```
Schedule (cron) → MP3 Generator → [S3 .mp3] → MP4 Converter → [S3 .mp4] → YouTube Uploader → YouTube
```

All infrastructure runs in `us-east-1` on a serverless stack (Lambda, S3, EventBridge, SSM).

## Directory Structure

```
terragrunt-infrastructure/
├── terragrunt.hcl                      # Root config: remote state (S3 + DynamoDB), AWS provider
├── _terraform-state-s3-bucket/         # Bootstrap: state bucket + DynamoDB lock table (standalone TF)
└── prod/
    ├── env.hcl                         # Topic-level vars (topic, bucket names, tags)
    ├── common/                         # Shared resources (not topic-specific)
    │   ├── env.hcl                     # Common env vars (no topic)
    │   ├── s3-content-bucket/          # S3 bucket for MP3, MP4, images, metadata
    │   ├── s3-prompts-bucket/          # S3 bucket for daily prompts
    │   ├── layer-ffmpeg/               # Lambda layer: ffmpeg binary
    │   ├── layer-youtube-deps/         # Lambda layer: google-api-python-client
    │   ├── mp3-generator/              # Lambda: Bedrock + Polly → MP3
    │   ├── mp4-converter/              # Lambda: ffmpeg image + audio → MP4
    │   └── youtube-uploader/           # Lambda: upload to YouTube
    └── history/                        # Topic-specific resources (topic = "history")
        ├── eventbridge-mp3/            # Cron rule: daily 6 AM UTC → MP3 Generator
        ├── s3-notifications/           # S3 event notifications: .mp3 → MP4, .mp4 → YouTube
        └── ssm/                        # YouTube OAuth credentials (SecureString)
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Terragrunt installed

## Bootstrap (First Time Only)

The state backend must exist before running Terragrunt. Bootstrap it with standalone Terraform:

```bash
cd _terraform-state-s3-bucket
terraform init
terraform apply
```

This creates:
- S3 bucket `content-generator-state-bucket` (KMS encrypted, versioned, public access blocked)
- DynamoDB table `terraform-state-lock` for state locking

## Commands

Run all commands from the `terragrunt-infrastructure/` directory.

### Initialize

```bash
terragrunt stack run init
```

### Plan

```bash
terragrunt stack run plan
```

### Apply

```bash
terragrunt stack run apply
```

## Dependency Order

Terragrunt resolves dependencies automatically. The apply sequence is:

```
1. s3-content-bucket, s3-prompts-bucket, layer-ffmpeg, layer-youtube-deps, ssm  (parallel)
2. mp3-generator, mp4-converter, youtube-uploader                                (depend on layers)
3. eventbridge-mp3, s3-notifications                                             (depend on Lambdas + S3)
```

Dependency graph:

```
s3-content-bucket ──────────────────────────┐
s3-prompts-bucket                           │
layer-ffmpeg ──────→ mp4-converter ─────────┤
layer-youtube-deps → youtube-uploader ──────┼──→ s3-notifications
                     mp3-generator ─────────┼──→ eventbridge-mp3
ssm                                         │
```

## State Management

| Aspect | Details |
|---|---|
| Backend | S3 (`content-generator-state-bucket`) |
| Locking | DynamoDB (`terraform-state-lock`) |
| Encryption | Enabled (KMS) |
| Isolation | Per-module state file via `path_relative_to_include()` |

Each Terragrunt unit gets its own state file, e.g.:
- `prod/common/mp3-generator/terraform.tfstate`
- `prod/history/eventbridge-mp3/terraform.tfstate`

## Configuration

Shared variables are centralized in `env.hcl` files:

| File | Scope | Key Variables |
|---|---|---|
| `prod/common/env.hcl` | Shared resources | `environment`, `content_bucket`, `prompts_bucket`, `common_tags` |
| `prod/env.hcl` | Topic-specific | `topic`, `content_bucket`, `prompts_bucket`, `common_tags` (includes Topic tag) |

## Adding a New Topic

1. Create a new folder under `prod/` (e.g., `prod/motivation/`)
2. Add `env.hcl` with the new topic name and tags
3. Copy the `history/` subfolder structure (`eventbridge-mp3/`, `s3-notifications/`, `ssm/`)
4. Update `topic` in the new `env.hcl`
5. Run `terragrunt stack run apply`

## Post-Deploy: SSM Credentials

SSM parameters are created with placeholder value `CHANGE_ME`. After apply, set the real values:

```bash
aws ssm put-parameter --name /youtube/{topic}/client_id --value "<client_id>" --type SecureString --overwrite
aws ssm put-parameter --name /youtube/{topic}/client_secret --value "<client_secret>" --type SecureString --overwrite
aws ssm put-parameter --name /youtube/{topic}/refresh_token --value "<refresh_token>" --type SecureString --overwrite
```

Terragrunt will not overwrite these on subsequent applies (`ignore_changes = [value]`).

## Tagging Strategy

```hcl
# Base tags (from env.hcl)
Environment = "production"
ManagedBy   = "terragrunt"
Topic       = "history"          # only in topic-level env.hcl

# Per-resource (merged in each terragrunt.hcl)
Component   = "mp3-generator"    # varies per module
```
