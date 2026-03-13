# MP3 Generator — Improvements

## Critical

- **No error handling** — Any failure (Bedrock timeout, Polly error, S3 read miss) crashes the Lambda with no recovery. Add try/except with structured logging and consider DLQ.

## High

- **No DLQ configured** — A failed invocation silently drops the day's content. Add an SQS dead-letter queue.
- **No retry logic** — Bedrock and Polly calls have no application-level retries. Use exponential backoff for transient failures.
- **No CloudWatch Alarms** — Failures go unnoticed. Add alarms on Lambda errors, throttles, and duration.
- **No X-Ray tracing** — Enable active tracing for distributed debugging across the pipeline.

## Medium

- **Memory may be tight at 256 MB** — Two Bedrock API calls with large SSML responses could push memory limits. Monitor `Max Memory Used` and consider bumping to 512 MB.
- **Bedrock read timeout (120s)** — Long SSML generation could still timeout. Consider increasing or adding retry.
- **Polly IAM uses `Resource: *`** — Polly doesn't support resource-level permissions for `StartSpeechSynthesisTask`, but add `Condition` block to restrict by `aws:RequestedRegion`.
- **Bedrock IAM wildcard on `foundation-model/*`** — Scope to specific model ARN pattern (e.g., `anthropic.claude-*`).
- **No idempotency** — Duplicate EventBridge invocations produce duplicate content. Consider checking if today's output already exists.
- **Metadata code-block stripping is fragile** — The `startswith('```')` parsing could break on unexpected Bedrock output. Use proper JSON extraction.

## Low

- **No input validation** — Missing `prompts_bucket` in event causes unhandled KeyError. Validate inputs early.
- **Polly async timing** — Lambda returns before MP3 lands in S3. This is by design (EventBridge handles it), but worth documenting.
- **Switch to arm64 (Graviton2)** — ~20% cheaper and often faster for Python workloads.
