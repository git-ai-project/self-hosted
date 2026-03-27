# Git AI — Self-Hosted

This repository contains the official self-hosting packages for **Git AI Enterprise**. Git AI tracks AI-generated code in your repositories, linking every AI-written line to the agent, model, and conversation transcripts that produced it — giving your team full lifecycle visibility from prompt to production.

> **Commercial software.** Self-hosting Git AI requires a valid **Git AI Enterprise License**. See [Licensing](#licensing) below.

---

## Self-Hosting Options

Full documentation for each deployment method is in its respective folder (`docker-compose/` or `helm/`).

### Docker Compose — [`docker-compose/`](./docker-compose/)

> **For quick local testing only.** The Docker Compose setup is intended for getting Git AI running locally or for very small proof-of-concept evaluations. We do not recommend it for anything beyond that — use the Helm chart for real deployments.

Runs the full Git AI stack on a single machine using Docker Compose.

- PostgreSQL, Valkey (Redis-compatible), and ClickHouse included
- Local storage and local batch processing by default — no cloud dependencies required
- Optional cloud storage backends (S3, Azure Blob, GCS)
- One-command bootstrap: `task bootstrap`

**[Quick start →](./docker-compose/README.md)**

---

### Kubernetes / Helm — [`helm/`](./helm/)

Deploys Git AI to a Kubernetes cluster via a Helm chart. Supports cloud-native storage, multiple ingress controllers, and per-cloud provider value overlays.

- Bitnami PostgreSQL and Valkey included as Helm dependencies
- ClickHouse StatefulSet included (simplified single-node for POCs — for production deployments, we recommend running a dedicated ClickHouse cluster or connecting to [ClickHouse Cloud](https://clickhouse.com/cloud))
- Storage backends: local PVC, S3, Azure Blob, GCS
- Ingress modes: nginx, Istio
- Pre-built overlays for EKS, GKE, AKS, Istio, and Minikube

Best for: teams already running Kubernetes who want scalable, cloud-native deployments.

**[Quick start →](./helm/README.md)**

---

## Licensing

Git AI Enterprise (this repo) is **commercial software** and requires a **Git AI Enterprise License** to operate. It is *not* free open source software, unlike the [Git AI CLI](https://github.com/git-ai-project/git-ai).

- A `LICENSE_KEY` environment variable must be set in your deployment configuration before Git AI will start.
- Licenses are issued per organization. Contact us to obtain or renew a license.

To get a license or learn more about Git AI Enterprise:

- **Book a call:** [calendly.com/d/cxjh-z79-ktm/meeting-with-git-ai-authors](https://calendly.com/d/cxjh-z79-ktm/meeting-with-git-ai-authors)
- **Docs:** [usegitai.com/docs](https://usegitai.com/docs)
- **GitHub:** [github.com/git-ai-project/git-ai](https://github.com/git-ai-project/git-ai)

---

## About Git AI

Git AI is an open-source Git extension that brings AI code attribution to your existing workflow — no per-repo setup, no workflow changes, no login required for the CLI. The Enterprise tier adds self-hosted transcript stores, access control, PII filtering, secret redaction, and cross-team dashboards aggregating AI composition metrics across repositories and organizations.

Learn more at [usegitai.com/docs](https://usegitai.com/docs).
