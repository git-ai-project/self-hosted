# Operations

## Service Lifecycle

- Start: `task up`
- Wait for readiness: `task wait`
- Stop: `task down`
- Status: `task status`
- Logs: `task logs -- <service>`

## Migrations

`task up` automatically runs one-shot migrators before app containers start.
Migration scripts and SQL are embedded in the EE image under `/app/scripts` and `/app/migrations`.

You can run them manually:

```bash
task migrate
```

Both migrators are idempotent and keep migration journals in the target databases.

## Health Checks

- Web: `GET /api/health`
- DB/Redis/ClickHouse container healthchecks in compose

## BullMQ Dashboard

- URL: `http://localhost:3001` by default
- Env toggles:
  - `BULLMQ_DASHBOARD_ENABLED` (default `true`)
  - `BULLMQ_DASHBOARD_PORT` (default `3001`)
- Warning: BullMQ dashboard has no built-in auth. Restrict access with firewall/VPN/reverse-proxy auth.

## Backups

Back up at least:

- Postgres volume
- ClickHouse volume
- Redis volume (optional depending on retention needs)
