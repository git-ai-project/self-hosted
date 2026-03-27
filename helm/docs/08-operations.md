# Operations

## Service Lifecycle

- Install/upgrade: `task up`
- Wait for readiness: `task wait`
- Uninstall: `task down`
- Status: `task status`
- Logs: `task logs -- <target>`

## Migrations

Migration jobs run as Helm hooks (`post-install,post-upgrade`).
They use the same EE image configured under `image.repository` / `image.tag` and run migration scripts from `/app/scripts` with SQL in `/app/migrations`.

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

## Backups

Back up at least:

- PostgreSQL PVC
- ClickHouse PVC
- Valkey PVC (optional depending on retention needs)
- Worker storage PVC when `storage.backend=local`
