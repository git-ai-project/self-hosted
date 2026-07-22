# Upgrades

## Upgrade Image Tag

1. Update `image.repository` / `image.tag` and
   `migrations.clickhouseImage.repository` / `tag` in
   `generated/values.local.yaml`. For an app commit tag such as `abc1234`, the
   matching migrator tag is `abc1234-clickhouse-migrator`.
2. Re-run release upgrade:

```bash
task up
task wait
task doctor
```

Migration hooks run on `task up` (`post-install,post-upgrade`). Postgres uses
the EE app image; ClickHouse uses the dedicated migrator image.
