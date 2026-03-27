# Git AI Self-Hosting (Helm POC)

This package deploys a full Git AI self-hosted stack on Kubernetes using Helm.

## Includes

- Postgres (Bitnami chart dependency)
- Valkey (Bitnami chart dependency)
- ClickHouse (native StatefulSet)
- Postgres + ClickHouse migration Jobs (Helm hooks)
- Web deployment + service + traffic entry (nginx ingress or Istio gateway)
- Worker deployment + optional BullMQ dashboard service
- Migration scripts/assets embedded in the EE runtime image (`web/Dockerfile.ee`)
- Migrators execute scripts from `/app/scripts` and SQL from `/app/migrations`

## Storage Backends

`storage.backend` supports:

- `local` (default): PVC-backed `/app/data`
- `aws`: bucket-backed worker storage, app storage volumes are `emptyDir`
- `azure`: blob-backed worker storage, app storage volumes are `emptyDir`
- `gcp`: GCS-backed worker storage, app storage volumes are `emptyDir`

## Traffic Modes

`ingress.mode` supports:

- `nginx` (default): renders Kubernetes `Ingress`
- `istio`: renders Istio `Gateway` + `VirtualService`

Portable defaults:

- `ingress.enabled=false`
- `ingress.className=""`
- `ingress.annotations={}`

`ingress.cloud` presets for `nginx` mode:

- `generic` (default): no class/annotation assumptions
- `aws`: ALB-friendly class/annotations defaults
- `gcp`: GKE ingress annotation default (`kubernetes.io/ingress.class=gce`)
- `azure`: AKS app-routing class default (`webapprouting.kubernetes.azure.com`)

All presets are overrideable via `ingress.className` and `ingress.annotations`.

Provider overlays are included:

- `values.aws.yaml`
- `values.gcp.yaml`
- `values.azure.yaml`
- `values.istio.yaml`

## Quick Start

1. Git clone this repo locally
2. `task init`
3. Edit `generated/values.local.yaml`:
   - set `secrets.licenseKey`
   - set ingress/global URLs (`ingress.enabled`, `ingress.mode`, `ingress.cloud`, host)
4. `task scm:configure`
   Use the default slug for each provider unless you are configuring multiple instances of that provider.
5. `task up`
6. `task wait`
7. `task doctor`

Managed cloud shortcuts:

- `task up -- -f values.aws.yaml`
- `task up -- -f values.gcp.yaml`
- `task up -- -f values.azure.yaml`
- `task up -- -f values.istio.yaml`

## Main Commands

- `task up`
- `task down`
- `task status`
- `task logs -- web`
- `task doctor`
- `task test:render`
- `task admin:grant -- <email-or-id>`

## Minikube Notes

- Enable ingress addon: `minikube addons enable ingress`
- Add local DNS/hosts entry for the ingress host from `generated/values.local.yaml`
- Use `task up -- -f values.minikube.yaml` to layer minikube overrides

## Docs

- `docs/00-overview.md`
- `docs/01-prereqs.md`
- `docs/02-quickstart.md`
- `docs/03-configuration.md`
- `docs/04-scm-github.md`
- `docs/05-scm-gitlab.md`
- `docs/06-scm-bitbucket.md`
- `docs/07-admin-bootstrap.md`
- `docs/08-operations.md`
- `docs/09-troubleshooting.md`
- `docs/10-upgrades.md`
