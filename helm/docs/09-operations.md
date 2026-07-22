# Operations

## Service Lifecycle

- Install/upgrade: `task up`
- Wait for readiness: `task wait`
- Uninstall: `task down`
- Status: `task status`
- Logs: `task logs -- <target>`

## Migrations

Migration jobs run as Helm hooks (`post-install,post-upgrade`).
The Postgres job uses the EE app image configured under `image`. The ClickHouse
job uses the dedicated image configured under `migrations.clickhouseImage`.
Each image contains its migration script and SQL assets.

Useful commands:

```bash
task logs -- migrator-postgres
task logs -- migrator-clickhouse
```

To re-run migrations after config/image changes, run:

```bash
task up
```

## Health Checks

- Web app: `GET /api/health` (through ingress host)
- Workload readiness: `task wait`
- Cluster status snapshot: `task status`

## Database Access

- `task admin:psql` opens a `psql` shell against the application database `gitai` by default.
- If you changed `postgresql.auth.database`, run it with `APP_DB_NAME=<your-db> task admin:psql`.

## BullMQ Dashboard

If `worker.dashboard.enabled=true`, a ClusterIP service is created.

Find the service and port-forward:

```bash
kubectl get svc -n "${HELM_NAMESPACE:-git-ai}" | rg worker-dashboard
kubectl port-forward -n "${HELM_NAMESPACE:-git-ai}" svc/<worker-dashboard-service> 3001:3001
```

## Optional SQL API

If `sqlApi.enabled=true`, a dedicated SQL API deployment and Service are created.

Find the service and port-forward:

```bash
kubectl get svc -n "${HELM_NAMESPACE:-git-ai}" | rg -- '-sql'
kubectl port-forward -n "${HELM_NAMESPACE:-git-ai}" svc/<sql-service> 5432:5432
```

## Backups

Back up at least:

- PostgreSQL PVC
- ClickHouse PVC
- Valkey PVC (optional depending on retention needs)
- Worker storage PVC when `storage.backend=local`
