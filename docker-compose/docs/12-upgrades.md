# Upgrades

## Upgrade Image Tag

1. Set/update `WEB_IMAGE` in `.env`
2. Pull and restart:

```bash
docker compose pull
task up
```

Migration scripts/assets ship in the EE image and are executed by the one-shot migrator services.
