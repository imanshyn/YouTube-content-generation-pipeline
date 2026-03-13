# MP4 Converter Lambda

## Overview

Second stage of the automated content pipeline. Combines an MP3 audio file with a background image to produce an MP4 video using ffmpeg.

## Pipeline Position

```
MP3 Generator → S3 .mp3 → [MP4 Converter] → S3 .mp4 → YouTube Uploader
```

## How It Works

1. Triggered by EventBridge rule when a `.mp3` file is created in the S3 content bucket
2. Downloads the MP3 from S3
3. Downloads a background image (date-specific or fallback default)
4. Runs ffmpeg to combine image + audio → MP4 (1080p, H.264, AAC)
5. Uploads the MP4 back to S3 in the same prefix

## Configuration

| Parameter | Source |
|---|---|
| S3 bucket/key | Parsed from event payload |
| Image path | `{topic}/image/{date}.png` with fallback to `{topic}/image/image.png` |

## Runtime

| Attribute | Value |
|---|---|
| Runtime | Python 3.12 |
| Memory | 1024 MB |
| Timeout | 600s |
| Layers | ffmpeg binary |
| Trigger | EventBridge rule on S3 `Object Created` with `.mp3` suffix |
| Ephemeral Storage | 512 MB (default) |

## AWS Services Used

- **S3** — Read MP3 + image, write MP4

## S3 Key Structure

```
# Input
{topic}/{date}/*.mp3
{topic}/image/{date}.png   (or {topic}/image/image.png fallback)

# Output
{topic}/{date}/*.mp4
```

## ffmpeg Settings

- Video: H.264, veryfast preset, CRF 23, 30fps, 1920x1080
- Audio: AAC 192k, 48kHz
- Flags: `-shortest`, `+faststart`

## Deployment

Deployed via Terragrunt from `terragrunt-infrastructure/prod/common/mp4-converter/`. Depends on `layer-ffmpeg` for the ffmpeg binary.

### Building the ffmpeg Layer

```bash
cd helpers/
bash build_ffmpeg_layer.sh
```
