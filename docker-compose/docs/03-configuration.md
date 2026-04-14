# Configuration

## Required `.env` Keys

- `WEB_BASE_URL`: public base URL for users and webhooks
- `BETTER_AUTH_URL`: auth callback base URL (normally same as `WEB_BASE_URL`)
- `LICENSE_KEY`: required for startup
- `BETTER_AUTH_SECRET`: auth signing secret
- `WORKER_JWT_SECRET`: worker auth secret
- `WEB_INTERNAL_API_KEY`: internal API auth key
- `SCM_WEBHOOK_SECRET_KEY`: encryption key for stored webhook secrets
- `DATABASE_URL`
- `REDIS_URL`
- `CLICKHOUSE_HTTP_URL`
- `CLICKHOUSE_USER`
- `CLICKHOUSE_PASSWORD`
- `CLICKHOUSE_DATABASE`

## Common Defaults

- `ANALYZE_BATCH_PROVIDER=local`
- `STORAGE_BACKEND=local`
- `LOCAL_STORAGE_PATH=/app/data/worker-storage`
- `BULLMQ_PREFIX={git-ai}`
- `BULLMQ_DASHBOARD_ENABLED=true`
- `BULLMQ_DASHBOARD_PORT=3001`

## Email Delivery

Email is optional overall, but invitation delivery requires a configured provider.

- `EMAIL_PROVIDER=disabled` (default): email sending is off
- `EMAIL_PROVIDER=resend`:
  - requires `EMAIL_FROM`
  - requires `RESEND_API_KEY`
- `EMAIL_PROVIDER=smtp`:
  - requires `EMAIL_FROM`
  - requires `SMTP_HOST`
  - requires `SMTP_PORT`
  - optional `SMTP_USERNAME` + `SMTP_PASSWORD` (must be set together)
  - optional `SMTP_SECURE` (defaults to `true` for port `465`, else `false`)
  - optional `SMTP_REQUIRE_TLS` (defaults to `true` when `SMTP_SECURE=false`)
  - optional `SMTP_TLS_REJECT_UNAUTHORIZED` (defaults to `true`)

Backward compatibility:

- `RESEND_FROM_EMAIL` is still accepted as a fallback alias for `EMAIL_FROM`
- if `EMAIL_PROVIDER` is unset, the app infers `resend` from `RESEND_API_KEY`
- if `EMAIL_PROVIDER` is unset, the app infers `smtp` when both `SMTP_HOST` and `SMTP_PORT` are set

## Storage Backend Requirements

- `STORAGE_BACKEND=local` or `filesystem`
  - Requires `LOCAL_STORAGE_PATH`
- `STORAGE_BACKEND=aws`
  - Requires `WORKER_STORAGE_BUCKET_NAME`
- `STORAGE_BACKEND=azure`
  - Requires `AZURE_STORAGE_CONNECTION_STRING`
  - Optional `AZURE_STORAGE_CONTAINER` (default `git-ai-worker-storage`)
- `STORAGE_BACKEND=gcp`
  - Requires `GCP_STORAGE_BUCKET` (or `WORKER_STORAGE_BUCKET_NAME`)

## Analyze Batch Provider

- `ANALYZE_BATCH_PROVIDER=local` is the recommended/default self-host setting.
- `local` requires no extra analyze-batch env vars.
- `aws` requires:
  - `ANALYZE_BATCH_AWS_JOB_QUEUE`
  - `ANALYZE_BATCH_AWS_JOB_DEFINITION`
- `gcp` and `azure` are not implemented in this build.

## SCM Config Output

`task scm:configure` writes:

- `config/scm-apps.generated.json`
- `generated/scm.env` with `SCM_APPS_CONFIG='[...]'`

Compose loads `generated/scm.env` automatically.

Provider buttons on the sign-in page are config-driven:

- GitHub button appears only if a GitHub app is configured.
- GitLab button appears only if a GitLab app is configured.
- Bitbucket button appears only if a Bitbucket app is configured.

Slug guidance:

- Default slugs: `github`, `gitlab`, `bitbucket`
- Change a slug only if you run multiple instances of the same provider
