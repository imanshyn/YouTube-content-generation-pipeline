# YouTube Uploader Lambda

## Overview

Third and final stage of the automated content pipeline. Downloads the generated MP4 video and metadata from S3, then uploads to YouTube via the Google API.

## Pipeline Position

```
MP3 Generator → MP4 Converter → S3 .mp4 → [YouTube Uploader] → YouTube
```

## How It Works

1. Triggered by EventBridge rule when a `.mp4` file is created in the S3 content bucket
2. Downloads the MP4 from S3
3. Reads `metadata.json` from the same S3 prefix (title, description, tags)
4. Retrieves YouTube OAuth credentials from SSM Parameter Store
5. Uploads video to YouTube as public with metadata

## Configuration

| Parameter | Source |
|---|---|
| S3 bucket/key | Parsed from event payload |
| YouTube OAuth creds | SSM Parameter Store (`/youtube/{topic}/client_id`, `client_secret`, `refresh_token`) |

## Runtime

| Attribute | Value |
|---|---|
| Runtime | Python 3.12 |
| Memory | 512 MB |
| Timeout | 300s |
| Layers | google-api-python-client |
| Trigger | EventBridge rule on S3 `Object Created` with `.mp4` suffix |

## AWS Services Used

- **S3** — Read MP4 and metadata.json
- **SSM Parameter Store** — YouTube OAuth credentials (SecureString)

## External Dependencies

- **Google YouTube Data API v3** — Video upload

## S3 Key Structure

```
# Input
{topic}/{date}/*.mp4
{topic}/{date}/metadata.json
```

## OAuth Setup

1. Create project in [Google Cloud Console](https://console.cloud.google.com/) and enable YouTube Data API v3
2. Create OAuth 2.0 credentials
3. Generate refresh token using `helpers/generate_refresh_token.py`
4. Store credentials in SSM:

```bash
aws ssm put-parameter --name /youtube/{topic}/client_id --value "<client_id>" --type SecureString
aws ssm put-parameter --name /youtube/{topic}/client_secret --value "<client_secret>" --type SecureString
aws ssm put-parameter --name /youtube/{topic}/refresh_token --value "<refresh_token>" --type SecureString
```

## Deployment

Deployed via Terragrunt from `terragrunt-infrastructure/prod/common/youtube-uploader/`. Depends on `layer-youtube-deps` for Google API Python dependencies.

### Building the Dependencies Layer

```bash
cd helpers/
pip install -r requirements.txt -t ../layer/python/
bash build_layer.sh
```
