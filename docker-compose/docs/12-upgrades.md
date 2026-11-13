# Upgrades

## Upgrade Image Tag

1. Set/update `WEB_IMAGE` in `.env`
2. Pull and restart:

```bash
docker compose pull
task up
```

Migration scripts/assets ship in the EE image and are executed by the one-shot migrator services.

`task up` saves a generated `CUBEJS_API_SECRET` in `.env` if your installation lacks a valid Cube signing key. If you run `docker compose up` directly, run `task init` first to provision the key.
