# Upgrades

## Upgrade Image Tag

1. Update `image.repository` and/or `image.tag` in `generated/values.local.yaml`.
2. Re-run release upgrade:

```bash
task up
task wait
task doctor
```

Migration hooks run on `task up` (`post-install,post-upgrade`) and use the same EE image.
Migrations are executed from `/app/scripts` and `/app/migrations` inside that image.
