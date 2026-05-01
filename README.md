# Git AI — Self-Hosted

This repository contains the official self-hosting packages for **Git AI Enterprise**. Git AI tracks AI-generated code in your repositories, linking every AI-written line to the agent, model, and conversation transcripts that produced it — giving your team full lifecycle visibility from prompt to production.

> **Commercial software.** Self-hosting Git AI requires a valid **Git AI Enterprise License**. See [Licensing](#licensing) below.

---

## Self-Hosting Options

Full documentation for each deployment method is in its respective folder (`docker-compose/` or `helm/`).

<img width="1051" height="741" alt="image" src="https://github.com/user-attachments/assets/e145f8cd-279a-49dc-8f30-03f5611175d2" />


### Docker Compose — [`docker-compose/`](./docker-compose/)

> **For quick local testing only.** The Docker Compose setup is intended for getting Git AI running locally or for very small proof-of-concept evaluations. We do not recommend it for anything beyond that — use the Helm chart for real deployments.

Runs the full Git AI stack on a single machine using Docker Compose.

- PostgreSQL, Valkey (Redis-compatible), and ClickHouse included
- Local storage and local batch processing by default — no cloud dependencies required
- Optional cloud storage backends (S3, Azure Blob, GCS)

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

## Recommended Infrastructure

The Helm chart deploys five components: **Web** (API/UI), **Worker** (background jobs), **PostgreSQL**, **Valkey** (Redis-compatible), and **ClickHouse** (analytics). Below are sizing guidelines for a production deployment.

### Compute

| Component | CPU (request / limit) | Memory (request / limit) | Default replicas |
|---|---|---|---|
| Web | 500m / 2 | 1 Gi / 2 Gi | 1 |
| Worker | 500m / 2 | 1 Gi / 2 Gi | 1 |
| ClickHouse | 250m / 2 | 512 Mi / 4 Gi | 1 |
| PostgreSQL | Bitnami defaults | Bitnami defaults | 1 |
| Valkey | Bitnami defaults | Bitnami defaults | 1 |

**Minimum cluster size:** A single 4-vCPU / 16 GB node can run a proof-of-concept with default resource requests (excluding Kubernetes overhead). For production, we recommend **at least 3 nodes with 4+ vCPU and 16 GB each** to allow workloads to spread and tolerate a node failure.

### Storage

| Volume | Default size | Notes |
|---|---|---|
| PostgreSQL | 20 Gi | Stores users, orgs, SCM metadata |
| Valkey | 10 Gi | Job queue persistence (`noeviction` policy) |
| ClickHouse | 30 Gi | Analytics events — grows with repository activity |
| Worker local storage | 20 Gi | Only used when `storage.backend=local` |

All PVCs require a `StorageClass` that supports dynamic provisioning. If your cluster has no default `StorageClass`, set one explicitly for each volume in your values file. Use SSD-backed storage classes for PostgreSQL and ClickHouse.

For production deployments using cloud object storage (S3, Azure Blob, or GCS), the worker local PVC is not needed — set `storage.backend` to your cloud provider instead.

### Networking

- **Ingress:** Choose between nginx-based Ingress (with presets for AWS ALB, GCP GCE, and Azure app routing) or Istio Gateway/VirtualService. See `helm/docs/03-configuration.md` for details.
- **TLS:** Terminate TLS at the ingress layer. The chart supports `ingress.tls` configuration for certificate secrets.
- **Outbound access:** Application pods need HTTPS egress to your SCM provider (GitHub, GitLab, or Bitbucket) for webhook delivery and API calls.
- **Inbound access:** Your SCM provider must be able to reach the ingress endpoint at `global.webBaseUrl` to deliver webhooks.
- **Internal:** All inter-component communication stays within the cluster via ClusterIP services on ports 3000 (web), 5432 (PostgreSQL), 6379 (Valkey), and 8123/9000 (ClickHouse).

### Cloud-Specific Notes

- **AWS (EKS):** Use the `values.aws.yaml` overlay. Requires the AWS Load Balancer Controller. Use `gp3` storage class for PVCs and S3 for worker storage.
- **GCP (GKE):** Use the `values.gcp.yaml` overlay. Uses the built-in GCE Ingress controller. Use `premium-rwo` storage class and GCS for worker storage.
- **Azure (AKS):** Use the `values.azure.yaml` overlay. Enable the AKS app routing add-on. Use `managed-premium` storage class and Azure Blob for worker storage.

---

## Scalability and Performance

### Horizontal Scaling

The **Web** and **Worker** deployments support horizontal scaling via `web.replicas` and `worker.replicas`. Both deployments expose `nodeSelector`, `tolerations`, and `affinity` fields for controlling pod placement.

**Web** pods are stateless and can be freely scaled behind the ingress load balancer. Increase replicas to handle higher API and webhook throughput.

**Worker** pods process background jobs from Valkey via BullMQ. Adding replicas increases parallel job processing capacity. All workers share the same Valkey queue, so scaling is straightforward.

> **Local storage limitation:** When `storage.backend=local`, the worker PVC uses `ReadWriteOnce` access mode, which restricts all worker pods to a single node. For multi-node worker scaling, switch to a cloud storage backend (S3, Azure Blob, or GCS).

### Database Scaling

- **PostgreSQL** is deployed via the Bitnami subchart in standalone mode. For high-availability setups, configure the Bitnami chart's replication settings or point the chart at an externally managed database (RDS, Cloud SQL, Azure Database for PostgreSQL) by disabling the subchart and providing a `DATABASE_URL` in your existing secret.
- **Valkey** is deployed in standalone mode with persistence enabled and a `noeviction` memory policy (required for BullMQ reliability). For HA, configure Bitnami Valkey replication or use a managed Redis-compatible service (ElastiCache, Memorystore, Azure Cache).
- **ClickHouse** runs as a single-replica StatefulSet. This is suitable for small-to-medium deployments. For production workloads with heavy analytics queries or large event volumes, connect to an external [ClickHouse Cloud](https://clickhouse.com/cloud) cluster or a self-managed ClickHouse cluster by disabling the in-chart ClickHouse and configuring external connection details.

### Performance Tuning

- **ClickHouse storage:** ClickHouse is the most storage-intensive component over time. Monitor disk usage and increase `clickhouse.persistence.size` as your repository activity grows. The chart enables `query_log` with a 7-day TTL by default; disable it if storage is constrained.
- **Resource limits:** The default resource limits are conservative starting points. Monitor actual usage with your cluster's metrics stack and adjust `resources.requests` and `resources.limits` accordingly.
- **Org sync scheduling:** The worker runs a periodic organization sync (default: daily at 3 AM ET via `worker.orgSync.cronPattern`). For large organizations with many repositories, consider scheduling this during off-peak hours and monitoring job duration via the BullMQ dashboard (`worker.dashboard.enabled=true`).

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
