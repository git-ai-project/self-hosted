# Prerequisites

Install:

- Kubernetes cluster access (for example, minikube)
- `kubectl`
- `helm` (v3)
- `task` CLI ([go-task](https://taskfile.dev/))
- Node.js 22+ (for the SCM wizard script)
- `openssl` CLI (used by `task init` to generate secrets)

You also need:

- A valid Git AI enterprise `LICENSE_KEY`
- At least one SCM app configured (GitHub, GitLab, and/or Bitbucket)
- For most installs, one app per provider with the default slug (`github`, `gitlab`, `bitbucket`)

## Storage Requirements

- For default persistent mode, your cluster needs a default `StorageClass` for dynamic provisioning.
- If your cluster has no default `StorageClass`, set storage classes explicitly in values for:
  - `storage.local.pvc.storageClass`
  - `postgresql.primary.persistence.storageClass`
  - `valkey.primary.persistence.storageClass`
  - `clickhouse.persistence.storageClass`

## Network Requirements

- Cluster pull access to your configured `image.repository` (EE image registry)
- Cluster pull access to Helm dependency registries (Bitnami charts)
- Outbound access from app pods to configured SCM providers
- Inbound access from SCM webhook delivery to your exposed host (`global.webBaseUrl`)

## Traffic Controller Requirements

- Only required when `ingress.enabled=true`.
- `ingress.mode=nginx`:
  - Generic/minikube: install nginx ingress controller
  - AWS preset (`ingress.cloud=aws`): install AWS Load Balancer Controller
  - GCP preset (`ingress.cloud=gcp`): use GKE Ingress controller
  - Azure preset (`ingress.cloud=azure`): enable AKS app routing add-on
- `ingress.mode=istio`:
  - Istio CRDs installed
  - An Istio ingress gateway deployed (chart defaults target selector `istio=ingressgateway`)

## Minikube Notes

- Enable ingress addon: `minikube addons enable ingress`
- Point your local DNS/hosts entry at the ingress host configured in `generated/values.local.yaml`
