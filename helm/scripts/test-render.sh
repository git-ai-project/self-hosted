#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

helm dependency update . >/dev/null

helm lint . >/dev/null

helm template local . > "$TMP_DIR/local.yaml"
if ! rg -q "name: local-git-ai-self-hosting-storage" "$TMP_DIR/local.yaml"; then
  echo "Expected app storage PVC in local backend render" >&2
  exit 1
fi
if rg -q 'name: RESEND_API_KEY' "$TMP_DIR/local.yaml"; then
  echo "Did not expect RESEND_API_KEY env in disabled email render" >&2
  exit 1
fi
if rg -q 'name: SMTP_PASSWORD' "$TMP_DIR/local.yaml"; then
  echo "Did not expect SMTP_PASSWORD env in disabled email render" >&2
  exit 1
fi
if ! rg -q "claimName: local-git-ai-self-hosting-storage" "$TMP_DIR/local.yaml"; then
  echo "Expected app persistentVolumeClaim mount in local backend render" >&2
  exit 1
fi
if rg -q "kind: Ingress" "$TMP_DIR/local.yaml"; then
  echo "Did not expect Ingress resource in portable default render" >&2
  exit 1
fi
if rg -q "kind: Gateway" "$TMP_DIR/local.yaml"; then
  echo "Did not expect Istio Gateway in portable default render" >&2
  exit 1
fi
if rg -q "kind: VirtualService" "$TMP_DIR/local.yaml"; then
  echo "Did not expect Istio VirtualService in portable default render" >&2
  exit 1
fi

cat > "$TMP_DIR/aws-values.yaml" <<'YAML'
storage:
  backend: aws
  aws:
    workerBucketName: demo-bucket
ingress:
  enabled: true
  cloud: aws
YAML
helm template aws . -f "$TMP_DIR/aws-values.yaml" > "$TMP_DIR/aws.yaml"
if rg -q "name: aws-git-ai-self-hosting-storage" "$TMP_DIR/aws.yaml"; then
  echo "Did not expect app storage PVC in aws backend render" >&2
  exit 1
fi
if ! rg -q "WORKER_STORAGE_BUCKET_NAME:" "$TMP_DIR/aws.yaml"; then
  echo "Expected WORKER_STORAGE_BUCKET_NAME config for aws backend" >&2
  exit 1
fi
if ! rg -q "emptyDir: \{\}" "$TMP_DIR/aws.yaml"; then
  echo "Expected emptyDir mounts for aws backend" >&2
  exit 1
fi
if ! rg -q "ingressClassName: \"alb\"" "$TMP_DIR/aws.yaml"; then
  echo "Expected ALB ingress class for aws cloud preset" >&2
  exit 1
fi
if ! rg -q "alb.ingress.kubernetes.io/scheme: internet-facing" "$TMP_DIR/aws.yaml"; then
  echo "Expected ALB ingress annotations for aws cloud preset" >&2
  exit 1
fi

cat > "$TMP_DIR/azure-values.yaml" <<'YAML'
storage:
  backend: azure
  azure:
    connectionStringSecretKey: AZURE_STORAGE_CONNECTION_STRING
    connectionString: DefaultEndpointsProtocol=https;AccountName=test;AccountKey=test;EndpointSuffix=core.windows.net
ingress:
  enabled: true
  cloud: azure
YAML
helm template azure . -f "$TMP_DIR/azure-values.yaml" > "$TMP_DIR/azure.yaml"
if rg -q "name: azure-git-ai-self-hosting-storage" "$TMP_DIR/azure.yaml"; then
  echo "Did not expect app storage PVC in azure backend render" >&2
  exit 1
fi
if ! rg -q "name: AZURE_STORAGE_CONNECTION_STRING" "$TMP_DIR/azure.yaml"; then
  echo "Expected AZURE_STORAGE_CONNECTION_STRING env for azure backend" >&2
  exit 1
fi
if ! rg -q "emptyDir: \{\}" "$TMP_DIR/azure.yaml"; then
  echo "Expected emptyDir mounts for azure backend" >&2
  exit 1
fi
if ! rg -q "ingressClassName: \"webapprouting.kubernetes.azure.com\"" "$TMP_DIR/azure.yaml"; then
  echo "Expected AKS app-routing ingress class for azure cloud preset" >&2
  exit 1
fi

cat > "$TMP_DIR/gcp-values.yaml" <<'YAML'
storage:
  backend: gcp
  gcp:
    bucketName: demo-bucket
ingress:
  enabled: true
  cloud: gcp
YAML
helm template gcp . -f "$TMP_DIR/gcp-values.yaml" > "$TMP_DIR/gcp.yaml"
if rg -q "name: gcp-git-ai-self-hosting-storage" "$TMP_DIR/gcp.yaml"; then
  echo "Did not expect app storage PVC in gcp backend render" >&2
  exit 1
fi
if ! rg -q "GCP_STORAGE_BUCKET:" "$TMP_DIR/gcp.yaml"; then
  echo "Expected GCP_STORAGE_BUCKET config for gcp backend" >&2
  exit 1
fi
if ! rg -q "emptyDir: \{\}" "$TMP_DIR/gcp.yaml"; then
  echo "Expected emptyDir mounts for gcp backend" >&2
  exit 1
fi
if ! rg -q "kubernetes.io/ingress.class: gce" "$TMP_DIR/gcp.yaml"; then
  echo "Expected GKE ingress annotation for gcp cloud preset" >&2
  exit 1
fi
if rg -q "ingressClassName:" "$TMP_DIR/gcp.yaml"; then
  echo "Did not expect ingressClassName field for gcp cloud preset" >&2
  exit 1
fi

cat > "$TMP_DIR/istio-values.yaml" <<'YAML'
ingress:
  enabled: true
  mode: istio
YAML
helm template istio . -f "$TMP_DIR/istio-values.yaml" > "$TMP_DIR/istio.yaml"
if ! rg -q "kind: Gateway" "$TMP_DIR/istio.yaml"; then
  echo "Expected Istio Gateway in istio mode render" >&2
  exit 1
fi
if ! rg -q "kind: VirtualService" "$TMP_DIR/istio.yaml"; then
  echo "Expected Istio VirtualService in istio mode render" >&2
  exit 1
fi
if rg -q "kind: Ingress" "$TMP_DIR/istio.yaml"; then
  echo "Did not expect Kubernetes Ingress in istio mode render" >&2
  exit 1
fi

cat > "$TMP_DIR/istio-tls-values.yaml" <<'YAML'
ingress:
  enabled: true
  mode: istio
  tls:
    - secretName: git-ai-web-tls
YAML
helm template istio-tls . -f "$TMP_DIR/istio-tls-values.yaml" > "$TMP_DIR/istio-tls.yaml"
if ! rg -q "credentialName: \"git-ai-web-tls\"" "$TMP_DIR/istio-tls.yaml"; then
  echo "Expected Istio Gateway TLS credentialName from ingress.tls[].secretName" >&2
  exit 1
fi
if ! rg -q "name: https-0" "$TMP_DIR/istio-tls.yaml"; then
  echo "Expected Istio Gateway TLS server for ingress.tls entry" >&2
  exit 1
fi
if ! rg -q '^\s*- "localhost"$' "$TMP_DIR/istio-tls.yaml"; then
  echo "Expected Istio Gateway TLS hosts to default to ingress.hosts" >&2
  exit 1
fi

cat > "$TMP_DIR/istio-existing-gateway-values.yaml" <<'YAML'
ingress:
  enabled: true
  mode: istio
  istio:
    gateway:
      create: false
      name: shared-ingress
      namespace: istio-ingress
YAML
helm template istio-existing-gw . -f "$TMP_DIR/istio-existing-gateway-values.yaml" > "$TMP_DIR/istio-existing-gw.yaml"
if rg -q "kind: Gateway" "$TMP_DIR/istio-existing-gw.yaml"; then
  echo "Did not expect Gateway creation when ingress.istio.gateway.create=false" >&2
  exit 1
fi
if ! rg -q "istio-ingress/shared-ingress" "$TMP_DIR/istio-existing-gw.yaml"; then
  echo "Expected VirtualService to reference existing namespaced Gateway" >&2
  exit 1
fi

cat > "$TMP_DIR/smtp-values.yaml" <<'YAML'
email:
  provider: smtp
  from: notifications@example.com
  smtp:
    host: smtp.example.com
    port: 587
    username: mailer
    password: super-secret
    secure: false
    requireTls: true
    tlsRejectUnauthorized: false
YAML
helm template smtp . -f "$TMP_DIR/smtp-values.yaml" > "$TMP_DIR/smtp.yaml"
if ! rg -q 'EMAIL_PROVIDER: "smtp"' "$TMP_DIR/smtp.yaml"; then
  echo "Expected EMAIL_PROVIDER=smtp config in SMTP render" >&2
  exit 1
fi
if ! rg -q 'name: SMTP_PASSWORD' "$TMP_DIR/smtp.yaml"; then
  echo "Expected SMTP_PASSWORD secret env in SMTP render" >&2
  exit 1
fi
if ! rg -q 'SMTP_HOST: "smtp.example.com"' "$TMP_DIR/smtp.yaml"; then
  echo "Expected SMTP_HOST config in SMTP render" >&2
  exit 1
fi
if rg -q 'name: RESEND_API_KEY' "$TMP_DIR/smtp.yaml"; then
  echo "Did not expect RESEND_API_KEY env in SMTP render" >&2
  exit 1
fi

cat > "$TMP_DIR/resend-values.yaml" <<'YAML'
email:
  provider: resend
  from: notifications@example.com
  resend:
    apiKey: re_test_key
YAML
helm template resend . -f "$TMP_DIR/resend-values.yaml" > "$TMP_DIR/resend.yaml"
if ! rg -q 'EMAIL_PROVIDER: "resend"' "$TMP_DIR/resend.yaml"; then
  echo "Expected EMAIL_PROVIDER=resend config in Resend render" >&2
  exit 1
fi
if ! rg -q 'name: RESEND_API_KEY' "$TMP_DIR/resend.yaml"; then
  echo "Expected RESEND_API_KEY secret env in Resend render" >&2
  exit 1
fi
if rg -q 'name: SMTP_PASSWORD' "$TMP_DIR/resend.yaml"; then
  echo "Did not expect SMTP_PASSWORD env in Resend render" >&2
  exit 1
fi

cat > "$TMP_DIR/invalid-smtp-values.yaml" <<'YAML'
email:
  provider: smtp
  from: notifications@example.com
  smtp:
    host: smtp.example.com
    username: mailer
YAML
if helm template invalid-smtp . -f "$TMP_DIR/invalid-smtp-values.yaml" >/dev/null 2>&1; then
  echo "Expected invalid SMTP config to fail chart validation" >&2
  exit 1
fi

cat > "$TMP_DIR/task-aws-values.yaml" <<'YAML'
ingress:
  enabled: true
YAML
helm template task-aws . -f values.yaml -f generated/values.local.yaml -f values.aws.yaml -f "$TMP_DIR/task-aws-values.yaml" > "$TMP_DIR/task-aws.yaml"
if ! rg -q "ingressClassName: \"alb\"" "$TMP_DIR/task-aws.yaml"; then
  echo "Expected ALB ingress class with task layering + aws overlay" >&2
  exit 1
fi
if rg -q "ingressClassName: \"nginx\"" "$TMP_DIR/task-aws.yaml"; then
  echo "Did not expect nginx ingress class with task layering + aws overlay" >&2
  exit 1
fi

helm template task-gcp . -f values.yaml -f generated/values.local.yaml -f values.gcp.yaml > "$TMP_DIR/task-gcp.yaml"
if ! rg -q "kubernetes.io/ingress.class: gce" "$TMP_DIR/task-gcp.yaml"; then
  echo "Expected GKE ingress annotation with task layering + gcp overlay" >&2
  exit 1
fi
if rg -q "ingressClassName: \"nginx\"" "$TMP_DIR/task-gcp.yaml"; then
  echo "Did not expect nginx ingress class with task layering + gcp overlay" >&2
  exit 1
fi

helm template task-azure . -f values.yaml -f generated/values.local.yaml -f values.azure.yaml > "$TMP_DIR/task-azure.yaml"
if ! rg -q "ingressClassName: \"webapprouting.kubernetes.azure.com\"" "$TMP_DIR/task-azure.yaml"; then
  echo "Expected AKS app-routing ingress class with task layering + azure overlay" >&2
  exit 1
fi
if rg -q "ingressClassName: \"nginx\"" "$TMP_DIR/task-azure.yaml"; then
  echo "Did not expect nginx ingress class with task layering + azure overlay" >&2
  exit 1
fi

cat > "$TMP_DIR/istio-existing-gw-vs-gateways-values.yaml" <<'YAML'
ingress:
  enabled: true
  mode: istio
  istio:
    gateway:
      create: false
    virtualService:
      gateways:
        - istio-system/shared-public
YAML
helm template istio-existing-gw-vs-gateways . -f "$TMP_DIR/istio-existing-gw-vs-gateways-values.yaml" > "$TMP_DIR/istio-existing-gw-vs-gateways.yaml"
if ! rg -q "istio-system/shared-public" "$TMP_DIR/istio-existing-gw-vs-gateways.yaml"; then
  echo "Expected explicit virtualService.gateways reference when gateway.create=false" >&2
  exit 1
fi

echo "Render tests passed"
