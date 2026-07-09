{{/*
Expand the name of the chart.
*/}}
{{- define "kodus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kodus.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "kodus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kodus.labels" -}}
helm.sh/chart: {{ include "kodus.chart" . }}
{{ include "kodus.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "kodus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kodus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "kodus.componentSelectorLabels" -}}
{{- include "kodus.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "kodus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "kodus.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end }}

{{- define "kodus.hooksServiceAccountName" -}}
{{- if and .Values.serviceAccount.create .Values.serviceAccount.hooks.create -}}
{{- default (printf "%s-hooks" (include "kodus.fullname" .)) .Values.serviceAccount.hooks.name -}}
{{- else if .Values.serviceAccount.hooks.name -}}
{{- .Values.serviceAccount.hooks.name -}}
{{- else -}}
default
{{- end -}}
{{- end }}

{{- define "kodus.image" -}}
{{- $registry := default "ghcr.io/kodustech" .root.Values.image.registry -}}
{{- $component := .component -}}
{{- $tag := default .root.Chart.AppVersion .root.Values.image.tag -}}
{{- if eq $component "webhook" -}}
{{- printf "%s/kodus-ai-webhook:%s" $registry $tag -}}
{{- else if eq $component "mcp-manager" -}}
{{- printf "%s/kodus-mcp-manager:%s" $registry $tag -}}
{{- else -}}
{{- printf "%s/kodus-ai-%s:%s" $registry $component $tag -}}
{{- end -}}
{{- end }}

{{- define "kodus.secretKeyOrValueOrAutogen" -}}
{{- $secret := .secret -}}
{{- $key := .key -}}
{{- $value := .value -}}
{{- $generator := .generator -}}
{{- $root := .root -}}
{{- if and $secret $secret.data (hasKey $secret.data $key) -}}
{{- index $secret.data $key | b64dec -}}
{{- else if $value -}}
{{- $value -}}
{{- else if $generator -}}
{{- include $generator $root -}}
{{- end -}}
{{- end -}}

{{- define "kodus.mongoProductionConfig" -}}
{{- if .Values.externalMongodb.authSource -}}
{{- printf "?authSource=%s" .Values.externalMongodb.authSource -}}
{{- end -}}
{{- end -}}

{{- define "kodus.rabbitmqCredentials" -}}
{{- $user := .Values.externalRabbitmq.username -}}
{{- $pass := .Values.externalRabbitmq.password -}}
{{- if .Values.externalRabbitmq.existingSecret -}}
{{- $credsSecret := lookup "v1" "Secret" .Release.Namespace .Values.externalRabbitmq.existingSecret -}}
{{- if $credsSecret -}}
{{- if hasKey $credsSecret.data .Values.externalRabbitmq.usernameKey -}}
{{- $user = index $credsSecret.data .Values.externalRabbitmq.usernameKey | b64dec -}}
{{- end -}}
{{- if hasKey $credsSecret.data .Values.externalRabbitmq.passwordKey -}}
{{- $pass = index $credsSecret.data .Values.externalRabbitmq.passwordKey | b64dec -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- dict "user" $user "pass" $pass | toJson -}}
{{- end -}}

{{- define "kodus.rabbitmqUri" -}}
{{- if .Values.externalRabbitmq.uri -}}
{{- .Values.externalRabbitmq.uri -}}
{{- else -}}
{{- $creds := include "kodus.rabbitmqCredentials" . | fromJson -}}
{{- $host := .Values.externalRabbitmq.host -}}
{{- $port := .Values.externalRabbitmq.port -}}
{{- $vhost := .Values.externalRabbitmq.vhost -}}
{{- if $creds.user -}}
{{- printf "amqp://%s:%s@%s:%v/%s?heartbeat=60&frameMax=8192" $creds.user $creds.pass $host $port $vhost -}}
{{- else -}}
{{- printf "amqp://%s:%v/%s?heartbeat=60&frameMax=8192" $host $port $vhost -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kodus.needsRabbitmqUriSecret" -}}
{{- if or .Values.externalRabbitmq.uri .Values.externalRabbitmq.host -}}true{{- end -}}
{{- end -}}

{{- define "kodus.validateAnalyticsUriMode" -}}
{{- if .Values.externalPostgresql.uri -}}
{{- if or .Values.workerAnalytics.enabled .Values.cronRunner.workerAnalytics.enabled -}}
{{- fail "externalPostgresql.uri is incompatible with workerAnalytics / cronRunner.workerAnalytics: the analytics warehouse has no URL env var and requires discrete API_PG_DB_* (use host/port/username/database instead of uri, or disable analytics workers)" -}}
{{- end -}}
{{- if .Values.jobs.migrations.enabled -}}
{{- fail "externalPostgresql.uri is incompatible with jobs.migrations: migration hooks run analytics warehouse migrations which require discrete API_PG_DB_* vars (no ANALYTICS_PG_DB_URL); use host/port/username/database instead of uri" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kodus.validateCronRunner" -}}
{{- if .Values.cronRunner.enabled -}}
{{- if and .Values.cronRunner.api.enabled (gt (.Values.cronRunner.api.replicaCount | int) 1) -}}
{{- fail "cronRunner.api.replicaCount must be 1 — dedicated cron runners prevent duplicate @Cron schedules" -}}
{{- end -}}
{{- if and .Values.cronRunner.worker.enabled (gt (.Values.cronRunner.worker.replicaCount | int) 1) -}}
{{- fail "cronRunner.worker.replicaCount must be 1 — dedicated cron runners prevent duplicate @Cron schedules" -}}
{{- end -}}
{{- if and .Values.cronRunner.workerAnalytics.enabled (gt (.Values.cronRunner.workerAnalytics.replicaCount | int) 1) -}}
{{- fail "cronRunner.workerAnalytics.replicaCount must be 1 — dedicated cron runners prevent duplicate @Cron schedules" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kodus.validateRabbitmqSecret" -}}
{{- if and .Values.secrets.existingSecret (include "kodus.needsRabbitmqUriSecret" .) -}}
{{- /* When secrets.existingSecret is set, include rabbitmq-uri (and pg-uri/mongo-uri when using uri mode) in that Secret */ -}}
{{- end -}}
{{- end -}}

{{- define "kodus.validateExternalDeps" -}}
{{- if and (not .Values.externalPostgresql.uri) (not .Values.externalPostgresql.host) -}}
{{- fail "externalPostgresql.host or externalPostgresql.uri is required" -}}
{{- end -}}
{{- if and (not .Values.externalMongodb.uri) (not .Values.externalMongodb.host) -}}
{{- fail "externalMongodb.host or externalMongodb.uri is required" -}}
{{- end -}}
{{- if and (not .Values.externalRabbitmq.uri) (not .Values.externalRabbitmq.host) -}}
{{- fail "externalRabbitmq.uri or externalRabbitmq.host is required" -}}
{{- end -}}
{{- if and .Values.serviceAccount.hooks.create (not .Values.serviceAccount.create) -}}
{{- fail "serviceAccount.hooks.create requires serviceAccount.create — set serviceAccount.hooks.name to use a pre-existing hook ServiceAccount instead" -}}
{{- end -}}
{{- end -}}

{{- define "kodus.secretName" -}}
{{- if .Values.secrets.existingSecret -}}
{{- .Values.secrets.existingSecret -}}
{{- else -}}
{{- include "kodus.fullname" . -}}-secrets
{{- end -}}
{{- end -}}

{{- define "kodus.pgPasswordSecretRef" -}}
{{- if .Values.externalPostgresql.existingSecret -}}
secretKeyRef:
  name: {{ .Values.externalPostgresql.existingSecret }}
  key: {{ .Values.externalPostgresql.passwordKey }}
{{- else -}}
secretKeyRef:
  name: {{ include "kodus.secretName" . }}
  key: pg-password
{{- end -}}
{{- end -}}

{{- define "kodus.mongoPasswordSecretRef" -}}
{{- if .Values.externalMongodb.existingSecret -}}
secretKeyRef:
  name: {{ .Values.externalMongodb.existingSecret }}
  key: {{ .Values.externalMongodb.passwordKey }}
{{- else -}}
secretKeyRef:
  name: {{ include "kodus.secretName" . }}
  key: mongo-password
{{- end -}}
{{- end -}}

{{- define "kodus.internalApiHostname" -}}
{{- if .Values.web.apiHostname -}}
{{- .Values.web.apiHostname -}}
{{- else -}}
{{- printf "%s-api" (include "kodus.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "kodus.publicUrlScheme" -}}
{{- if .Values.publicUrls.api -}}
{{- if hasPrefix "https://" .Values.publicUrls.api -}}https{{- else -}}http{{- end -}}
{{- else if .Values.ingress.api.tls -}}https{{- else -}}http{{- end -}}
{{- end -}}

{{- define "kodus.publicWebUrlScheme" -}}
{{- if .Values.publicUrls.web -}}
{{- if hasPrefix "https://" .Values.publicUrls.web -}}https{{- else -}}http{{- end -}}
{{- else if .Values.ingress.web.tls -}}https{{- else -}}http{{- end -}}
{{- end -}}

{{- define "kodus.publicApiUrl" -}}
{{- if .Values.publicUrls.api -}}
{{- .Values.publicUrls.api -}}
{{- else if .Values.ingress.api.hostname -}}
{{- printf "%s://%s" (include "kodus.publicUrlScheme" .) .Values.ingress.api.hostname -}}
{{- else -}}
{{- fail "publicUrls.api or ingress.api.hostname is required" -}}
{{- end -}}
{{- end -}}

{{- define "kodus.publicWebUrl" -}}
{{- if .Values.publicUrls.web -}}
{{- .Values.publicUrls.web -}}
{{- else if .Values.ingress.web.hostname -}}
{{- printf "%s://%s" (include "kodus.publicWebUrlScheme" .) .Values.ingress.web.hostname -}}
{{- else -}}
{{- fail "publicUrls.web or ingress.web.hostname is required" -}}
{{- end -}}
{{- end -}}

{{- define "kodus.commonEnv" -}}
- name: API_NODE_ENV
  value: {{ .Values.global.nodeEnv | quote }}
- name: API_DATABASE_ENV
  value: {{ .Values.global.databaseEnv | quote }}
- name: API_DATABASE_DISABLE_SSL
  value: {{ .Values.global.databaseDisableSsl | quote }}
- name: API_LOG_LEVEL
  value: {{ .Values.global.logLevel | quote }}
- name: API_LOG_PRETTY
  value: {{ .Values.global.logPretty | quote }}
- name: API_RABBITMQ_ENABLED
  value: {{ .Values.global.rabbitmqEnabled | quote }}
- name: API_MCP_SERVER_ENABLED
  value: {{ .Values.global.mcpServerEnabled | quote }}
- name: KODUS_TELEMETRY_DISABLED
  value: {{ .Values.global.telemetryDisabled | quote }}
- name: RELEASE_VERSION
  value: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
{{- if .Values.externalPostgresql.uri }}
- name: API_PG_DB_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: pg-uri
{{- else }}
- name: API_PG_DB_HOST
  value: {{ .Values.externalPostgresql.host | quote }}
- name: API_PG_DB_PORT
  value: {{ .Values.externalPostgresql.port | quote }}
- name: API_PG_DB_USERNAME
  value: {{ .Values.externalPostgresql.username | quote }}
- name: API_PG_DB_DATABASE
  value: {{ .Values.externalPostgresql.database | quote }}
- name: API_PG_DB_PASSWORD
  valueFrom:
    {{- include "kodus.pgPasswordSecretRef" . | nindent 4 }}
{{- end }}
{{- if .Values.externalMongodb.uri }}
- name: API_MG_DB_URI
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: mongo-uri
{{- else }}
- name: API_MG_DB_HOST
  value: {{ .Values.externalMongodb.host | quote }}
- name: API_MG_DB_PORT
  value: {{ .Values.externalMongodb.port | quote }}
- name: API_MG_DB_USERNAME
  value: {{ .Values.externalMongodb.username | quote }}
- name: API_MG_DB_DATABASE
  value: {{ .Values.externalMongodb.database | quote }}
{{- if include "kodus.mongoProductionConfig" . }}
- name: API_MG_DB_PRODUCTION_CONFIG
  value: {{ include "kodus.mongoProductionConfig" . | quote }}
{{- end }}
- name: API_MG_DB_PASSWORD
  valueFrom:
    {{- include "kodus.mongoPasswordSecretRef" . | nindent 4 }}
{{- end }}
{{- if include "kodus.needsRabbitmqUriSecret" . }}
- name: API_RABBITMQ_URI
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: rabbitmq-uri
{{- end }}
- name: API_JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: jwt-secret
- name: API_JWT_REFRESH_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: jwt-refresh-secret
- name: API_CRYPTO_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: crypto-key
- name: CODE_MANAGEMENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: code-management-secret
- name: CODE_MANAGEMENT_WEBHOOK_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: code-management-webhook-token
- name: NEXTAUTH_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: nextauth-secret
{{- if .Values.global.mcpServerEnabled }}
- name: API_MCP_MANAGER_JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: mcp-manager-jwt-secret
- name: API_MCP_MANAGER_ENCRYPTION_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: mcp-manager-encryption-secret
{{- end }}
{{- end }}

{{- define "kodus.apiEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{ include "kodus.cronEnv" (dict "root" . "component" "api") }}
{{ include "kodus.apiDocsEnv" . }}
{{ include "kodus.platformIntegrationEnv" . }}
{{ include "kodus.llmEnv" . }}
- name: COMPONENT_TYPE
  value: api
- name: API_URL
  value: {{ include "kodus.publicApiUrl" . | quote }}
- name: API_FRONTEND_URL
  value: {{ include "kodus.publicWebUrl" . | quote }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_DOCS_BASIC_PASS" "key" .Values.secrets.keys.apiDocsBasicPass) }}
{{- end -}}

{{- define "kodus.workerEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{ include "kodus.cronEnv" (dict "root" . "component" "worker") }}
{{ include "kodus.platformIntegrationEnv" . }}
{{ include "kodus.llmEnv" . }}
- name: COMPONENT_TYPE
  value: worker
- name: WORKER_ROLE
  value: {{ .Values.worker.role | quote }}
- name: WORKER_HEALTH_PORT
  value: {{ include "kodus.workerHealthPort" . | quote }}
{{- end -}}

{{- define "kodus.cronRunnerApiEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{ include "kodus.cronEnv" (dict "root" . "component" "cron-api") }}
{{ include "kodus.apiDocsEnv" . }}
{{ include "kodus.platformIntegrationEnv" . }}
{{ include "kodus.llmEnv" . }}
- name: COMPONENT_TYPE
  value: api
- name: API_URL
  value: {{ include "kodus.publicApiUrl" . | quote }}
- name: API_FRONTEND_URL
  value: {{ include "kodus.publicWebUrl" . | quote }}
{{- end -}}

{{- define "kodus.cronRunnerWorkerEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{ include "kodus.cronEnv" (dict "root" . "component" "cron-worker") }}
{{ include "kodus.platformIntegrationEnv" . }}
{{ include "kodus.llmEnv" . }}
- name: COMPONENT_TYPE
  value: worker
- name: WORKER_ROLE
  value: {{ .Values.cronRunner.worker.role | quote }}
- name: WORKER_HEALTH_PORT
  value: {{ include "kodus.workerHealthPort" . | quote }}
{{- end -}}

{{- define "kodus.cronRunnerWorkerAnalyticsEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{ include "kodus.cronEnv" (dict "root" . "component" "cron-worker-analytics") }}
{{ include "kodus.llmEnv" . }}
- name: COMPONENT_TYPE
  value: worker
- name: WORKER_ROLE
  value: {{ .Values.cronRunner.workerAnalytics.role | quote }}
- name: WORKER_HEALTH_PORT
  value: {{ include "kodus.workerHealthPort" . | quote }}
{{- end -}}

{{- define "kodus.workerAnalyticsEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{ include "kodus.cronEnv" (dict "root" . "component" "worker-analytics") }}
{{ include "kodus.llmEnv" . }}
- name: COMPONENT_TYPE
  value: worker
- name: WORKER_ROLE
  value: {{ .Values.workerAnalytics.role | quote }}
- name: WORKER_HEALTH_PORT
  value: {{ include "kodus.workerHealthPort" . | quote }}
{{- end -}}

{{- define "kodus.webhooksEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{ include "kodus.cronEnv" (dict "root" . "component" "webhooks") }}
- name: COMPONENT_TYPE
  value: webhook
{{- end -}}

{{- define "kodus.webEnv" -}}
{{- include "kodus.webConfigEnv" . }}
{{- end -}}
