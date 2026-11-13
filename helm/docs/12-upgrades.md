# Upgrades

## Upgrade Image Tag

1. Update `image.repository` and/or `image.tag` in `generated/values.local.yaml`.
2. If using `secrets.existingSecret`, add a private `CUBEJS_API_SECRET` to that Secret before deploying an image that requires it. Generate a new key with `openssl rand -hex 32` if you do not already have one. In chart-managed mode, Helm adds the key on upgrade and preserves an existing valid value.
3. Re-run the release upgrade:

```bash
task up
task wait
task doctor
```

Migration hooks run on `task up` (`post-install,post-upgrade`) and use the same EE image.
Migrations are executed from `/app/scripts` and `/app/migrations` inside that image.
