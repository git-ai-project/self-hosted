# Overview

This self-hosting package runs:

- `web`: Git AI web app/API
- `worker`: BullMQ worker runtime + dashboard (`:3001`)
- `db`: Postgres
- `redis`: Valkey/Redis
- `clickhouse`: analytics store
- `migrator-postgres`: one-shot schema migrator
- `migrator-clickhouse`: one-shot schema migrator

Both migrators run from the same EE image used by `web`/`worker`.
Migration scripts and SQL are embedded in the image under `/app/scripts` and `/app/migrations`.

## Design Goals

- Self-contained folder
- Beginner-friendly setup
- GitHub optional; at least one SCM required
- Automatic one-shot DB migrations on `docker compose up`

## Non-Goals

- TLS/reverse proxy management (bring your own ingress)
- Kubernetes deployment
