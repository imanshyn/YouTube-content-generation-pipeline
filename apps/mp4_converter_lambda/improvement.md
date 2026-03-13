# MP4 Converter — Improvements

## Critical

- **Event payload parsing bug** — Lambda parses `event['Records'][0]['s3']` but is triggered by EventBridge, which delivers `event['detail']['bucket']['name']` / `event['detail']['object']['key']`. This causes a `KeyError` at runtime. Fix the parsing to use EventBridge format.

## High

- **No DLQ configured** — A failed ffmpeg conversion silently drops the day's video. Add an SQS dead-letter queue.
- **No error handling** — ffmpeg crash, S3 download failure, or missing image all result in unhandled exceptions. Add try/except with structured logging.
- **No CloudWatch Alarms** — Add alarms on Lambda errors, throttles, and duration.
- **No X-Ray tracing** — Enable for pipeline-wide debugging.

## Medium

- **Ephemeral storage limited to 512 MB** — MP3 + image + output MP4 must all fit in `/tmp`. Longer audio files could exceed this. Configure `ephemeral_storage` to 1024 MB in Terraform.
- **No idempotency** — Duplicate EventBridge events cause re-processing and overwrite. Consider checking if MP4 already exists.
- **No `CONTENT_BUCKET` env var** — Lambda infers bucket from event payload. If event format is fixed, this works, but an explicit env var adds resilience.
- **ffmpeg binary version not pinned** — `build_ffmpeg_layer.sh` may pull different versions between builds. Pin the version.

## Low

- **No subprocess timeout** — `subprocess.run` has no timeout parameter. A hung ffmpeg process runs until Lambda timeout (600s). Add `timeout=540`.
- **No /tmp cleanup** — Files persist across warm invocations. Add cleanup to avoid stale data or disk pressure.
- **Switch to arm64 (Graviton2)** — ~20% cheaper. Ensure ffmpeg layer is compiled for arm64.
