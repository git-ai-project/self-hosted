{{- define "gitai.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gitai.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "gitai.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gitai.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gitai.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "gitai.labels" -}}
helm.sh/chart: {{ include "gitai.chart" . }}
{{ include "gitai.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "gitai.secretName" -}}
{{- if .Values.secrets.existingSecret -}}
{{- .Values.secrets.existingSecret -}}
{{- else -}}
{{- printf "%s-secrets" (include "gitai.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "gitai.configMapName" -}}
{{- printf "%s-config" (include "gitai.fullname" .) -}}
{{- end -}}

{{- define "gitai.storagePvcName" -}}
{{- printf "%s-storage" (include "gitai.fullname" .) -}}
{{- end -}}

{{- define "gitai.clickhouseServiceName" -}}
{{- printf "%s-clickhouse" (include "gitai.fullname" .) -}}
{{- end -}}

{{- define "gitai.clickhouseHeadlessServiceName" -}}
{{- printf "%s-clickhouse-headless" (include "gitai.fullname" .) -}}
{{- end -}}

{{- define "gitai.postgresqlHost" -}}
{{- if .Values.postgresql.fullnameOverride -}}
{{- .Values.postgresql.fullnameOverride -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "gitai.valkeyHost" -}}
{{- $base := "" -}}
{{- if .Values.valkey.fullnameOverride -}}
{{- $base = .Values.valkey.fullnameOverride -}}
{{- else -}}
{{- $base = printf "%s-valkey" .Release.Name -}}
{{- end -}}
{{- printf "%s-primary" $base -}}
{{- end -}}

{{- define "gitai.storageBackend" -}}
{{- lower (default "local" .Values.storage.backend) -}}
{{- end -}}

{{- define "gitai.ingressMode" -}}
{{- lower (default "nginx" .Values.ingress.mode) -}}
{{- end -}}

{{- define "gitai.ingressCloud" -}}
{{- lower (default "generic" .Values.ingress.cloud) -}}
{{- end -}}

{{- define "gitai.emailProvider" -}}
{{- lower (default "disabled" .Values.email.provider) -}}
{{- end -}}

{{- define "gitai.resendApiKey" -}}
{{- default .Values.secrets.resendApiKey .Values.email.resend.apiKey -}}
{{- end -}}

{{- define "gitai.ingressNginxClassName" -}}
{{- if .Values.ingress.className -}}
{{- .Values.ingress.className -}}
{{- else -}}
{{- $cloud := include "gitai.ingressCloud" . -}}
{{- if eq $cloud "aws" -}}
alb
{{- else if eq $cloud "azure" -}}
webapprouting.kubernetes.azure.com
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "gitai.ingressNginxCloudAnnotations" -}}
{{- $cloud := include "gitai.ingressCloud" . -}}
{{- if eq $cloud "aws" -}}
kubernetes.io/ingress.class: alb
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/healthcheck-path: /api/health
{{- else if eq $cloud "gcp" -}}
kubernetes.io/ingress.class: gce
{{- else -}}
{}
{{- end -}}
{{- end -}}

{{- define "gitai.ingressNginxAnnotations" -}}
{{- $cloud := include "gitai.ingressNginxCloudAnnotations" . | fromYaml | default (dict) -}}
{{- $custom := .Values.ingress.annotations | default (dict) -}}
{{- $merged := mergeOverwrite (dict) $cloud $custom -}}
{{- if gt (len $merged) 0 -}}
{{- toYaml $merged -}}
{{- end -}}
{{- end -}}

{{- define "gitai.istioGatewayName" -}}
{{- if .Values.ingress.istio.gateway.name -}}
{{- .Values.ingress.istio.gateway.name -}}
{{- else -}}
{{- printf "%s-web" (include "gitai.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "gitai.istioGatewayNamespace" -}}
{{- default .Release.Namespace .Values.ingress.istio.gateway.namespace -}}
{{- end -}}

{{- define "gitai.istioGatewayRef" -}}
{{- $name := include "gitai.istioGatewayName" . -}}
{{- $ns := include "gitai.istioGatewayNamespace" . -}}
{{- if eq $ns .Release.Namespace -}}
{{- $name -}}
{{- else -}}
{{- printf "%s/%s" $ns $name -}}
{{- end -}}
{{- end -}}

{{- define "gitai.validateValues" -}}
{{- $backend := include "gitai.storageBackend" . -}}
{{- if not (has $backend (list "local" "aws" "azure" "gcp")) -}}
{{- fail (printf "storage.backend must be one of: local, aws, azure, gcp (got %q)" .Values.storage.backend) -}}
{{- end -}}

{{- $ingressMode := include "gitai.ingressMode" . -}}
{{- if not (has $ingressMode (list "nginx" "istio")) -}}
{{- fail (printf "ingress.mode must be one of: nginx, istio (got %q)" .Values.ingress.mode) -}}
{{- end -}}

{{- $ingressCloud := include "gitai.ingressCloud" . -}}
{{- if not (has $ingressCloud (list "generic" "aws" "gcp" "azure")) -}}
{{- fail (printf "ingress.cloud must be one of: generic, aws, gcp, azure (got %q)" .Values.ingress.cloud) -}}
{{- end -}}

{{- $emailProvider := include "gitai.emailProvider" . -}}
{{- if not (has $emailProvider (list "disabled" "resend" "smtp")) -}}
{{- fail (printf "email.provider must be one of: disabled, resend, smtp (got %q)" .Values.email.provider) -}}
{{- end -}}

{{- if and .Values.ingress.enabled (empty .Values.ingress.hosts) -}}
{{- fail "ingress.hosts must contain at least one host when ingress.enabled=true" -}}
{{- end -}}

{{- if .Values.ingress.enabled -}}
{{- range $index, $host := .Values.ingress.hosts -}}
{{- if empty $host.host -}}
{{- fail (printf "ingress.hosts[%d].host must be set" $index) -}}
{{- end -}}
{{- if empty $host.paths -}}
{{- fail (printf "ingress.hosts[%d].paths must contain at least one path" $index) -}}
{{- end -}}
{{- range $pathIndex, $path := $host.paths -}}
{{- if empty $path.path -}}
{{- fail (printf "ingress.hosts[%d].paths[%d].path must be set" $index $pathIndex) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- if and .Values.ingress.enabled (eq $ingressMode "istio") -}}
{{- if and (not .Values.ingress.istio.gateway.create) (empty .Values.ingress.istio.gateway.name) (empty .Values.ingress.istio.virtualService.gateways) -}}
{{- fail "ingress.istio.gateway.name is required when ingress.mode=istio and ingress.istio.gateway.create=false" -}}
{{- end -}}
{{- range $index, $tls := .Values.ingress.tls -}}
{{- if empty $tls.secretName -}}
{{- fail (printf "ingress.tls[%d].secretName is required when ingress.mode=istio" $index) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- if eq $backend "local" -}}
{{- if empty .Values.storage.local.path -}}
{{- fail "storage.local.path is required when storage.backend=local" -}}
{{- end -}}
{{- if not .Values.storage.local.pvc.enabled -}}
{{- fail "storage.local.pvc.enabled must be true when storage.backend=local" -}}
{{- end -}}
{{- end -}}

{{- if eq $backend "aws" -}}
{{- if empty .Values.storage.aws.workerBucketName -}}
{{- fail "storage.aws.workerBucketName is required when storage.backend=aws" -}}
{{- end -}}
{{- end -}}

{{- if eq $backend "azure" -}}
{{- if empty .Values.storage.azure.connectionStringSecretKey -}}
{{- fail "storage.azure.connectionStringSecretKey is required when storage.backend=azure" -}}
{{- end -}}
{{- end -}}

{{- if eq $backend "gcp" -}}
{{- if empty .Values.storage.gcp.bucketName -}}
{{- fail "storage.gcp.bucketName is required when storage.backend=gcp" -}}
{{- end -}}
{{- end -}}

{{- if ne $emailProvider "disabled" -}}
{{- if empty .Values.email.from -}}
{{- fail "email.from is required when email.provider is resend or smtp" -}}
{{- end -}}
{{- end -}}

{{- if eq $emailProvider "resend" -}}
{{- if empty (include "gitai.resendApiKey" .) -}}
{{- fail "email.resend.apiKey (or deprecated secrets.resendApiKey) is required when email.provider=resend" -}}
{{- end -}}
{{- end -}}

{{- if eq $emailProvider "smtp" -}}
{{- if empty .Values.email.smtp.host -}}
{{- fail "email.smtp.host is required when email.provider=smtp" -}}
{{- end -}}
{{- if empty .Values.email.smtp.port -}}
{{- fail "email.smtp.port is required when email.provider=smtp" -}}
{{- end -}}
{{- if or (and .Values.email.smtp.username (not .Values.email.smtp.password)) (and .Values.email.smtp.password (not .Values.email.smtp.username)) -}}
{{- fail "email.smtp.username and email.smtp.password must both be set when SMTP auth is enabled" -}}
{{- end -}}
{{- end -}}
{{- end -}}
