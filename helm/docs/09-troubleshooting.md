# Troubleshooting

## Release install/upgrade fails

- Run `task doctor` for fast validation and render checks.
- Render manifests directly for inspection:

```bash
task render
```

## Pods or jobs not becoming ready

- Check current objects:

```bash
task status
```

- Inspect logs:

```bash
task logs -- web
task logs -- worker
task logs -- migrator-postgres
task logs -- migrator-clickhouse
```

## Storage backend validation errors

- `storage.backend=local` requires:
  - `storage.local.path`
  - `storage.local.pvc.enabled=true`
- `storage.backend=aws` requires `storage.aws.workerBucketName`
- `storage.backend=azure` requires `storage.azure.connectionStringSecretKey`
- `storage.backend=gcp` requires `storage.gcp.bucketName`

## Ingress host not reachable

- Confirm `ingress.enabled=true`.
- If `ingress.mode=nginx`, confirm ingress exists in namespace:

```bash
kubectl get ingress -n "${HELM_NAMESPACE:-git-ai}"
```

- If `ingress.mode=istio`, confirm gateway/virtualservice exist:

```bash
kubectl get gateway,virtualservice -n "${HELM_NAMESPACE:-git-ai}"
```

- Confirm local DNS/hosts maps your configured host to the external IP/hostname of the ingress gateway/load balancer.
- For `nginx` mode, confirm class/preset matches your cluster:
  - `ingress.cloud=aws` -> ALB defaults
  - `ingress.cloud=gcp` -> GKE defaults
  - `ingress.cloud=azure` -> AKS app-routing defaults
  - explicit `ingress.className`/`ingress.annotations` override presets

## OAuth callback mismatch

- Check provider callback URL exactly matches your `global.webBaseUrl`:
  - GitHub: `/api/auth/callback/github`
  - GitLab: `/api/auth/callback/gitlab`
  - Bitbucket: `/api/auth/oauth2/callback/bitbucket`

## SCM slug confusion

- If you only have one app for a provider, use the default slug: `github`, `gitlab`, or `bitbucket`
- Only change the slug when you intentionally configure multiple instances of the same provider
- Slugs must be unique because they are used in webhook URLs

## Webhooks not arriving

- Provider must reach your ingress host (`global.webBaseUrl`).
- Confirm firewall/DNS/reverse proxy forwarding.
- Confirm provider webhook secret matches SCM config.

## BullMQ dashboard not reachable

- Confirm dashboard is enabled:
  - `worker.dashboard.enabled=true`
- Confirm service exists and port-forward it (see operations doc).

## Book demo page still appears

- Ensure your user has `role='admin'` (`task admin:grant -- <email-or-id>`).
- In `/admin` -> Organizations, click **Mark Onboarding Complete** for your org.
