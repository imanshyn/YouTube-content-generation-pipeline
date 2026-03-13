# Automated YouTube Content Pipeline

Fully autonomous, serverless pipeline that generates and publishes daily YouTube videos. Reads a topic prompt, generates speech audio via AI, converts it to video, and uploads to YouTube — all without human intervention.

## Architecture
```
EventBridge Cron (daily 6 AM UTC)
        │
        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  MP3 Generator   │────▶│  MP4 Converter   │────▶│ YouTube Uploader │
│  Bedrock + Polly │     │  ffmpeg          │     │  Google API      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
   S3 .mp3 + metadata     S3 .mp4                 YouTube video
```
Three Lambda functions chained via EventBridge S3 event rules. S3 acts as both the data store and implicit event bus.

### Pipeline Stages

| Stage | Lambda | Trigger | What It Does |
|---|---|---|---|
| 1. Audio Generation | mp3-generator | EventBridge cron | Reads prompt from S3 → Bedrock (Claude) generates SSML → Polly synthesizes MP3 → writes metadata.json |
| 2. Video Creation | mp4-converter | S3 .mp3 created | Downloads MP3 + background image → ffmpeg combines into MP4 (1080p H.264) |
| 3. Publishing | youtube-uploader | S3 .mp4 created | Downloads MP4 + metadata → retrieves OAuth creds from SSM → uploads to YouTube |

### AWS Services

- Lambda — All compute (Python 3.12)
- S3 — Content storage (MP3, MP4, images, metadata, prompts)
- EventBridge — Cron scheduling + S3 event routing
- Amazon Bedrock — Claude model for SSML and metadata generation
- Amazon Polly — Async speech synthesis (generative engine)
- SSM Parameter Store — YouTube OAuth credentials (SecureString)

## Project Structure
```
├── apps/
│   ├── mp3_generator_lambda/       # Stage 1: Bedrock + Polly → MP3
│   ├── mp4_converter_lambda/       # Stage 2: ffmpeg image + audio → MP4
│   └── youtube_uploader_lambda/    # Stage 3: Upload to YouTube
├── terraform-modules/              # Reusable Terraform modules
│   ├── s3-bucket/
│   ├── lambda-function/
│   ├── lambda-layer/
│   ├── eventbridge/
│   ├── ssm-parameter/
│   └── s3-lambda-notification/
├── terragrunt-infrastructure/      # IaC orchestration (Terragrunt)
│   ├── terragrunt.hcl              # Root config: remote state, provider
│   └── prod/
│       ├── common/                 # Shared infra (Lambdas, S3, layers)
│       └── history/                # Topic-specific (EventBridge, SSM)
```
## S3 Key Conventions
# Prompts bucket
video-gen-prompts/{topic}/{date}.md

# Content bucket
```
{topic}/{date}/*.mp3                # Polly output
{topic}/{date}/*.mp4                # ffmpeg output
{topic}/{date}/metadata.json        # Video title/description/tags
{topic}/image/{date}.png            # Date-specific background (optional)
{topic}/image/image.png             # Default fallback background
```
## Getting Started

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Terragrunt
- Python 3.12

### Bootstrap State Backend
```
cd terragrunt-infrastructure/_terraform-state-s3-bucket
terraform init && terraform apply
```
### Deploy All Infrastructure
```
cd terragrunt-infrastructure
terragrunt stack run init
terragrunt stack run apply
```
### Set YouTube OAuth Credentials

SSM parameters are created with placeholder values. Set the real ones after deploy:
```
aws ssm put-parameter --name /youtube/{topic}/client_id --value "<client_id>" --type SecureString --overwrite
aws ssm put-parameter --name /youtube/{topic}/client_secret --value "<client_secret>" --type SecureString --overwrite
aws ssm put-parameter --name /youtube/{topic}/refresh_token --value "<refresh_token>" --type SecureString --overwrite
```
Use apps/youtube_uploader_lambda/helpers/generate_refresh_token.py to generate the refresh token.

## Adding a New Topic

1. Create a new folder under terragrunt-infrastructure/prod/ (e.g., `prod/motivation/`)
2. Add env.hcl with the topic name and tags
3. Copy the history/ subfolder structure (`eventbridge-mp3/`, s3-notifications/, `ssm/`)
4. Update topic in the new env.hcl
5. Add daily prompts to S3: video-gen-prompts/{topic}/{date}.md
6. Run terragrunt stack run apply

## Lambda Runtimes

| Lambda | Memory | Timeout | Layers |
|---|---|---|---|
| MP3 Generator | 128 MB | 300s | None |
| MP4 Converter | 4096 MB | 900s | ffmpeg |
| YouTube Uploader | 128 MB | 300s | google-api-python-client |

## Region

All resources deploy to us-east-1.
