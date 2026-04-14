# Configuration

## Required Inputs

- `secrets.licenseKey`
- `secrets.betterAuthSecret`
- `secrets.workerJwtSecret`
- `secrets.webInternalApiKey`
- `secrets.scmWebhookSecretKey`
- `secrets.scmAppsConfigJson` (use `task scm:configure`)

## Email Delivery

Set `email.provider` to one of:

- `disabled` (default): email sending is off
- `resend`: requires `email.from` and `email.resend.apiKey`
- `smtp`: requires `email.from`, `email.smtp.host`, and `email.smtp.port`

SMTP auth and TLS options:

- `email.smtp.username` + `email.smtp.password` are optional, but must be set together
- `email.smtp.secure` defaults to `false`
- `email.smtp.requireTls` defaults to `true`
- `email.smtp.tlsRejectUnauthorized` defaults to `true`

Backward compatibility:

- deprecated `secrets.resendApiKey` is still accepted as a fallback for `email.resend.apiKey`

## SCM App Slugs

Default slugs: `github`, `gitlab`, `bitbucket`.
Change a slug only if you run multiple instances of the same provider.

## Storage Backend

Set `storage.backend` to one of:

- `local`
- `aws`
- `azure`
- `gcp`

Validation rules:

- `local`: `storage.local.pvc.enabled=true` and `storage.local.path` required
- `aws`: `storage.aws.workerBucketName` required
- `azure`: `storage.azure.connectionStringSecretKey` required
- `gcp`: `storage.gcp.bucketName` required

Azure secret behavior:

- chart-managed secret mode (`secrets.existingSecret=""`): set `storage.azure.connectionString`
- existing secret mode (`secrets.existingSecret` set): provide key `storage.azure.connectionStringSecretKey` in that secret

## Traffic Entry

Set `ingress.mode` to one of:

- `nginx`: create Kubernetes `Ingress`
- `istio`: create Istio `Gateway` + `VirtualService`

Portable defaults:

- `ingress.enabled=false`
- `ingress.className=""`
- `ingress.annotations={}`

### nginx mode cloud presets

Set `ingress.cloud` to one of:

- `generic` (default): no class/annotation defaults
- `aws`: defaults for AWS Load Balancer Controller (`alb`)
- `gcp`: defaults for GKE Ingress (`kubernetes.io/ingress.class=gce`)
- `azure`: defaults for AKS app routing (`webapprouting.kubernetes.azure.com`)

Manual overrides always win:

- `ingress.className`
- `ingress.annotations`

Provider overlays in this chart:

- `values.aws.yaml`
- `values.gcp.yaml`
- `values.azure.yaml`
- `values.istio.yaml`

### istio mode options

- `ingress.istio.gateway.create=true` (default): chart creates a `Gateway`
- `ingress.istio.gateway.create=false`: chart reuses an existing gateway; set:
  - `ingress.istio.gateway.name`
  - optional `ingress.istio.gateway.namespace`
- `ingress.tls[*].secretName` maps to Istio `credentialName` when TLS is enabled
- if `ingress.tls[*].hosts` is omitted, Istio TLS servers default to all `ingress.hosts`
- `ingress.istio.virtualService.gateways` can override gateway references directly

## Org Sync Schedule

Controls when the worker runs the nightly org sync job. Both values are optional.

- `worker.orgSync.cronPattern` (default `0 3 * * *`): cron expression for the sync schedule. Examples: `0 3 * * *` (daily at 3 AM), `0 */6 * * *` (every 6 hours).
- `worker.orgSync.cronTz` (default `America/New_York`): IANA timezone for the cron schedule. Examples: `America/New_York`, `UTC`, `Europe/London`.

## Existing Secret Mode

Set `secrets.existingSecret` to use a pre-created secret instead of chart-managed secret generation.

Expected keys include at least:

- `DATABASE_URL`
- `REDIS_URL`
- `BETTER_AUTH_SECRET`
- `SCM_APPS_CONFIG`
- `WORKER_JWT_SECRET`
- `WEB_INTERNAL_API_KEY`
- `SCM_WEBHOOK_SECRET_KEY`
- `CLICKHOUSE_PASSWORD`
- `LICENSE_KEY`
- `RESEND_API_KEY` when `email.provider=resend`
- `SMTP_PASSWORD` when `email.provider=smtp` and `email.smtp.username` is set
- `AZURE_STORAGE_CONNECTION_STRING` (or your configured `storage.azure.connectionStringSecretKey`) when `storage.backend=azure`
