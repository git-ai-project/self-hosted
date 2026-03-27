# Git AI Self-Hosting (Docker Compose)

This package runs Git AI on a single machine with Docker Compose.

## Quick Start

1. Git clone this repository locally
2. `task init`
3. Edit `.env` (set at least `WEB_BASE_URL`, `BETTER_AUTH_URL`, `LICENSE_KEY`)
4. `task scm:configure` (GitHub is optional; configure at least one SCM app)
   Use the default slug for each provider unless you are configuring multiple instances of that provider.
5. `task up`
6. `task wait`
7. `task doctor`

Then open `http://localhost:3000` (or your configured domain).
BullMQ dashboard is available at `http://localhost:3001`.

This package defaults to `ANALYZE_BATCH_PROVIDER=local` (no extra batch env required).
It also defaults to `STORAGE_BACKEND=local` (no cloud storage bucket required).
Postgres/ClickHouse migrators run from the same EE image as `web`/`worker` using `/app/scripts` and `/app/migrations`.

This package does not configure TLS/reverse proxy automatically. Use your own ingress/reverse proxy in front of `web` as needed.

For a guided first-time run, use `task bootstrap`.

## Important First-Run Admin Step

After your first sign-in:

1. Promote your user in Postgres: `task admin:grant -- <your-email-or-user-id>`
2. Open `/admin`
3. Go to **Organizations**
4. For your org, click the action menu and choose **Mark Onboarding Complete**

This removes the book demo / booking-gated onboarding screen for that org.

## Main Commands

- `task bootstrap`: first-time guided setup
- `task up`: start services (includes one-shot migrators)
- `task wait`: wait for migrators + service readiness
- `task down`: stop services
- `task logs -- web`: tail logs for one service
- `task migrate`: run migrators manually
- `task status`: service status
- `task doctor`: config/health validation
- `task admin:psql`: open psql in DB container

## Image Override

- Set `WEB_IMAGE` in `.env` to pin a specific EE image tag/digest for `web`, `worker`, and both migrators.

## BullMQ Dashboard

- Default URL: `http://localhost:3001`
- Configure with:
  - `BULLMQ_DASHBOARD_ENABLED` (default `true`)
  - `BULLMQ_DASHBOARD_PORT` (default `3001`)
- Security note: this dashboard has no built-in auth. Do not expose it publicly without network-level protection.

## Docs

- `docs/00-overview.md`
- `docs/01-prereqs.md`
- `docs/02-quickstart.md`
- `docs/03-configuration.md`
- `docs/04-scm-github.md`
- `docs/05-scm-gitlab.md`
- `docs/06-scm-bitbucket.md`
- `docs/07-admin-bootstrap.md`
- `docs/08-operations.md`
- `docs/09-troubleshooting.md`
- `docs/10-upgrades.md`
