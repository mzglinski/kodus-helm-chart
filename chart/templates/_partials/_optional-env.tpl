{{- define "kodus.workflowEnv" -}}
- name: WORKFLOW_QUEUE_WORKER_PREFETCH
  value: {{ .Values.config.workflow.workerPrefetch | quote }}
- name: WORKFLOW_QUEUE_PUBLISHER_PREFETCH
  value: {{ .Values.config.workflow.publisherPrefetch | quote }}
- name: WORKFLOW_QUEUE_WEBHOOK_PREFETCH
  value: {{ .Values.config.workflow.webhookPrefetch | quote }}
- name: WORKFLOW_QUEUE_CODE_REVIEW_PREFETCH
  value: {{ .Values.config.workflow.codeReviewPrefetch | quote }}
- name: WORKFLOW_QUEUE_WEBHOOK_PROCESS_TIMEOUT_MS
  value: {{ .Values.config.workflow.webhookProcessTimeoutMs | quote }}
- name: WORKFLOW_QUEUE_CODE_REVIEW_PROCESS_TIMEOUT_MS
  value: {{ .Values.config.workflow.codeReviewProcessTimeoutMs | quote }}
- name: WORKFLOW_OUTBOX_MAX_ATTEMPTS
  value: {{ .Values.config.workflow.outboxMaxAttempts | quote }}
{{- end -}}

{{- define "kodus.runtimeFlagsEnv" -}}
- name: BETA_FEATURES
  value: {{ .Values.global.betaFeatures | quote }}
- name: API_AGENT_REVIEW_ENABLED
  value: {{ .Values.config.agentReviewEnabled | quote }}
- name: API_RABBITMQ_WAIT
  value: {{ .Values.config.rabbitmqWait | quote }}
- name: API_WORKER_DRAIN_TIMEOUT_MS
  value: {{ .Values.config.workerDrainTimeoutMs | quote }}
{{- if .Values.global.telemetryEndpoint }}
- name: KODUS_TELEMETRY_ENDPOINT
  value: {{ .Values.global.telemetryEndpoint | quote }}
{{- end }}
{{- end -}}

{{- define "kodus.apiDocsEnv" -}}
- name: API_DOCS_ENABLED
  value: {{ .Values.config.docs.enabled | quote }}
- name: API_DOCS_PATH
  value: {{ .Values.config.docs.path | quote }}
- name: API_DOCS_SPEC_PATH
  value: {{ .Values.config.docs.specPath | quote }}
{{- if .Values.config.docs.basicUser }}
- name: API_DOCS_BASIC_USER
  value: {{ .Values.config.docs.basicUser | quote }}
{{- end }}
{{- end -}}

{{- define "kodus.sandboxEnv" -}}
- name: SANDBOX_PROVIDER
  value: {{ .Values.config.sandbox.provider | quote }}
{{- end -}}

{{- define "kodus.emailEnv" -}}
- name: API_NOTIFICATION_EMAIL_PROVIDER
  value: {{ .Values.config.email.provider | quote }}
- name: API_USER_INVITE_BASE_URL
  value: {{ default (include "kodus.publicWebUrl" .) .Values.config.email.userInviteBaseUrl | quote }}
{{- if .Values.config.email.smtp.host }}
- name: API_SMTP_HOST
  value: {{ .Values.config.email.smtp.host | quote }}
{{- end }}
{{- if .Values.config.email.smtp.port }}
- name: API_SMTP_PORT
  value: {{ .Values.config.email.smtp.port | quote }}
{{- end }}
{{- if ne .Values.config.email.smtp.secure "" }}
- name: API_SMTP_SECURE
  value: {{ .Values.config.email.smtp.secure | quote }}
{{- end }}
{{- if .Values.config.email.smtp.user }}
- name: API_SMTP_USER
  value: {{ .Values.config.email.smtp.user | quote }}
{{- end }}
{{- if .Values.config.email.smtp.from }}
- name: API_SMTP_FROM
  value: {{ .Values.config.email.smtp.from | quote }}
{{- end }}
{{- end -}}

{{- define "kodus.mcpApiEnv" -}}
{{- if .Values.global.mcpServerEnabled }}
- name: API_KODUS_SERVICE_MCP_MANAGER
  value: {{ include "kodus.internalMcpManagerUrl" . | quote }}
- name: API_KODUS_MCP_SERVER_URL
  value: {{ printf "%s/mcp" (include "kodus.publicApiUrl" .) | quote }}
{{- end }}
{{- end -}}

{{/*
Git provider credentials, sandbox, email, and MCP wiring shared by api and worker.
kodus-installer passes the full .env to both services; worker webhook/code-review
jobs call GithubService and need the same GitHub App vars as the API.
*/}}
{{- define "kodus.platformIntegrationEnv" -}}
{{ include "kodus.sandboxEnv" . }}
{{ include "kodus.emailEnv" . }}
{{ include "kodus.mcpApiEnv" . }}
{{ include "kodus.githubApiEnv" . }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "RESEND_API_KEY" "key" .Values.secrets.keys.resendApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_SMTP_PASS" "key" .Values.secrets.keys.smtpPass) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_E2B_KEY" "key" .Values.secrets.keys.e2bKey) }}
{{- end -}}

{{- define "kodus.optionalSecretEnv" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $key := .key -}}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" $root }}
      key: {{ $key }}
      optional: true
{{- end -}}
