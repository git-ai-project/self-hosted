# Troubleshooting

## App crashes at startup with license errors

- Confirm `LICENSE_KEY` is set in `.env`
- Confirm key is valid for the image/build date

## `SCM_APPS_CONFIG` parse/validation errors

- Re-run `task scm:configure`
- Ensure `generated/scm.env` contains one non-empty JSON array
- Ensure at least one provider is configured
- Ensure providers are only `github`, `gitlab`, or `bitbucket`
- Ensure each SCM app slug is unique
- If you only have one app for a provider, use the default slug: `github`, `gitlab`, or `bitbucket`

## Analyze jobs failing immediately

- Confirm `ANALYZE_BATCH_PROVIDER=local` for Docker Compose self-hosting
- If using `aws`, set:
  - `ANALYZE_BATCH_AWS_JOB_QUEUE`
  - `ANALYZE_BATCH_AWS_JOB_DEFINITION`
- `gcp` and `azure` providers are currently not implemented

## Storage errors writing/reading worker artifacts

- Confirm `STORAGE_BACKEND` is set correctly.
- For `local`/`filesystem`: verify `LOCAL_STORAGE_PATH`.
- For `aws`: set `WORKER_STORAGE_BUCKET_NAME`.
- For `azure`: set `AZURE_STORAGE_CONNECTION_STRING`.
- For `gcp`: set `GCP_STORAGE_BUCKET` (or `WORKER_STORAGE_BUCKET_NAME`).

## OAuth callback mismatch

- Check provider callback URL exactly matches `WEB_BASE_URL` paths:
  - GitHub: `/api/auth/callback/github`
  - GitLab: `/api/auth/callback/gitlab`
  - Bitbucket: `/api/auth/oauth2/callback/bitbucket`

## Webhooks not arriving

- Provider must reach your `WEB_BASE_URL`
- Ensure firewall/DNS/reverse proxy forwards requests
- Confirm provider webhook secret matches SCM config

## BullMQ dashboard not reachable on `:3001`

- Check worker is running: `task status`
- Check worker logs: `task logs -- worker`
- Confirm `BULLMQ_DASHBOARD_ENABLED=true`
- Confirm host port `3001` is free or set `BULLMQ_DASHBOARD_PORT` to another port
- If using custom dashboard port, use that same port in the URL (`http://localhost:<BULLMQ_DASHBOARD_PORT>`)

## Book demo page still appears

- Make sure your user has `role='admin'`
- Go to `/admin` -> Organizations -> **Mark Onboarding Complete** for your org

## Migrator fails to start

- Confirm `WEB_IMAGE` points to an EE image that includes:
  - `/app/scripts/migrate-postgres.mjs`
  - `/app/scripts/migrate-clickhouse.sh`
  - `/app/migrations/postgres`
  - `/app/migrations/clickhouse`
- Re-pull image and restart: `docker compose pull && task up`

## ClickHouse running out of storage

ClickHouse system logs (`query_log`, `query_thread_log`, etc.) can consume 10s of GBs on active systems. As of this release, most system logs are disabled by default via `config/clickhouse-logging.xml`.

To diagnose storage issues:

```bash
docker exec -it <clickhouse-container> clickhouse-client \
  --user "${CLICKHOUSE_USER}" \
  --password "${CLICKHOUSE_PASSWORD}" \
  --query "
    SELECT
      database,
      table,
      formatReadableSize(sum(bytes_on_disk)) AS size,
      sum(rows) AS rows
    FROM system.parts
    WHERE active
    GROUP BY database, table
    ORDER BY sum(bytes_on_disk) DESC
    LIMIT 20
  "
```

To immediately free space by truncating system logs:

```bash
docker exec -it <clickhouse-container> clickhouse-client \
  --user "${CLICKHOUSE_USER}" \
  --password "${CLICKHOUSE_PASSWORD}" \
  --query "TRUNCATE TABLE system.query_log"
```

To adjust the TTL or disable `query_log` entirely, edit `config/clickhouse-logging.xml` and restart: `docker compose restart clickhouse`
