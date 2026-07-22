# Upgrades

## Upgrade Image Tag

1. Set/update `WEB_IMAGE` and `CLICKHOUSE_MIGRATOR_IMAGE` in `.env`.
   For a commit tag such as `abc1234`, the matching migrator tag is
   `abc1234-clickhouse-migrator`.
2. Pull and restart:

```bash
docker compose pull
task up
```

Postgres migrations ship in the EE image. ClickHouse migrations ship in the
dedicated ClickHouse migrator image.
