# Quickstart

## 1) Initialize local config

```bash
task init
```

## 2) Configure required values

Edit `generated/values.local.yaml`:

- `secrets.licenseKey`
- `global.webBaseUrl`
- `global.betterAuthUrl`
- `ingress.enabled` (`false` for internal-only or `true` to expose externally)
- `ingress.mode` (`nginx` or `istio`)
- `ingress.cloud` (`generic`, `aws`, `gcp`, `azure`) when `ingress.mode=nginx`
- `ingress.hosts[0].host`

## 3) Configure SCM apps

```bash
task scm:configure
```

Keep the default slug unless you run multiple instances of the same provider: `github`, `gitlab`, `bitbucket`.

## 4) Install stack

```bash
task up
task wait
task doctor
```

Managed cloud shortcuts:

- EKS + ALB defaults: `task up -- -f values.aws.yaml`
- GKE defaults: `task up -- -f values.gcp.yaml`
- AKS app-routing defaults: `task up -- -f values.azure.yaml`
- Istio mode: `task up -- -f values.istio.yaml`

Migration jobs use the same image configured under `image.repository` / `image.tag`.
