# YouTube Uploader — Improvements

## Critical

- **Event payload parsing bug** — Lambda parses `event['Records'][0]['s3']` but is triggered by EventBridge, which delivers `event['detail']['bucket']['name']` / `event['detail']['object']['key']`. This causes a `KeyError` at runtime. Fix the parsing to use EventBridge format.

## High

- **No DLQ configured** — A failed upload means the day's video is lost with no recovery. Add an SQS dead-letter queue.
- **No retry logic** — YouTube API quota limits or transient errors cause permanent failure. Add exponential backoff retries.
- **No CloudWatch Alarms** — Add alarms on Lambda errors, throttles, and duration.
- **No X-Ray tracing** — Enable for pipeline-wide debugging.
- **Duplicate uploads on retry** — No idempotency check. If EventBridge delivers the event twice, a duplicate video is uploaded to YouTube. Check if video was already uploaded before proceeding.

## Medium

- **Timeout may be insufficient (300s)** — Large MP4 uploads to YouTube over HTTPS can exceed 5 minutes. Consider increasing to 600s.
- **Ephemeral storage limited to 512 MB** — Must download full MP4 to `/tmp` before uploading. Large videos could exceed this.
- **IAM grants `ssm:PutParameter`** — Uploader only needs read access. Remove `PutParameter` permission unless token refresh writes back.
- **No /tmp cleanup** — Files persist across warm invocations. Add cleanup.

## Low

- **Hardcoded `categoryId: '22'`** — Category "People & Blogs" is hardcoded. Consider making it configurable via metadata or environment variable.
- **Hardcoded `privacyStatus: 'public'`** — Consider making configurable for testing (e.g., `unlisted` in non-prod).
- **No upload progress tracking** — `chunksize=-1` uploads in a single request. For large files, use chunked resumable upload with progress logging.
- **Switch to arm64 (Graviton2)** — ~20% cheaper for Python workloads.
