# MP3 Generator Lambda

## Overview

First stage of the automated content pipeline. Generates topic prompt based audio content by orchestrating Amazon Bedrock and Amazon Polly.

## Pipeline Position

```
EventBridge Cron → [MP3 Generator] → S3 .mp3 → MP4 Converter → YouTube Uploader
```

## How It Works

1. Reads today's prompt from S3 prompts bucket (`video-gen-prompts/{topic}/{date}.md`)
2. Sends prompt to Bedrock (Claude) to generate SSML speech content
3. Submits SSML to Amazon Polly (async) for MP3 synthesis → output lands in S3
4. Generates video metadata (title/description) via a second Bedrock call
5. Saves `metadata.json` to S3 for downstream YouTube upload

## Configuration

| Parameter | Source | Default |
|---|---|---|
| `OUTPUT_BUCKET` | Environment variable | Required |
| `BEDROCK_MODEL_ID` | Environment variable | `us.anthropic.claude-sonnet-4-20250514-v1:0` |
| `prompts_bucket` | Event payload | Required |
| `topic` | Event payload | `motivation` |
| `voice` | Event payload | `Stephen` |

## Runtime

| Attribute | Value |
|---|---|
| Runtime | Python 3.12 |
| Memory | 256 MB |
| Timeout | 300s |
| Layers | None |
| Trigger | EventBridge cron (`cron(0 6 * * ? *)` — daily 6 AM UTC) |

## AWS Services Used

- **S3** — Read prompts, write metadata
- **Bedrock** — Claude model for SSML and metadata generation
- **Polly** — Async speech synthesis (generative engine)

## S3 Key Structure

```
# Input (prompts bucket)
video-gen-prompts/{topic}/{date}.md

# Output (content bucket)
{topic}/{date}/metadata.json
{topic}/{date}/*.mp3          # Written by Polly async task
```

## Deployment

Deployed via Terragrunt from `terragrunt-infrastructure/prod/common/mp3-generator/`. Lambda code is zipped via `before_hook` on `plan`/`apply`.
