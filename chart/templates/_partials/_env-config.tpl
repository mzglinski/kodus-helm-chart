{{- define "kodus.backendConfigEnv" -}}
- name: GLOBAL_API_CONTAINER_NAME
  value: {{ .Values.config.globalApiContainerName | quote }}
- name: API_HOST
  value: "0.0.0.0"
- name: API_PORT
  value: {{ .Values.api.port | quote }}
- name: API_WEBHOOKS_PORT
  value: {{ .Values.webhooks.port | quote }}
- name: API_RATE_MAX_REQUEST
  value: {{ .Values.config.rateMaxRequest | quote }}
- name: API_RATE_INTERVAL
  value: {{ .Values.config.rateInterval | quote }}
- name: API_JWT_EXPIRES_IN
  value: {{ .Values.config.jwtExpiresIn | quote }}
- name: API_JWT_REFRESH_EXPIRES_IN
  value: {{ .Values.config.jwtRefreshExpiresIn | quote }}
- name: API_DEVELOPMENT_MODE
  value: {{ .Values.config.developmentMode | quote }}
- name: API_GITHUB_CODE_MANAGEMENT_WEBHOOK
  value: {{ printf "%s/github/webhook" (include "kodus.publicApiUrl" .) | quote }}
- name: API_GITLAB_CODE_MANAGEMENT_WEBHOOK
  value: {{ printf "%s/gitlab/webhook" (include "kodus.publicApiUrl" .) | quote }}
- name: GLOBAL_BITBUCKET_CODE_MANAGEMENT_WEBHOOK
  value: {{ printf "%s/bitbucket/webhook" (include "kodus.publicApiUrl" .) | quote }}
- name: GLOBAL_AZURE_REPOS_CODE_MANAGEMENT_WEBHOOK
  value: {{ printf "%s/azure-repos/webhook" (include "kodus.publicApiUrl" .) | quote }}
- name: API_FORGEJO_CODE_MANAGEMENT_WEBHOOK
  value: {{ printf "%s/forgejo/webhook" (include "kodus.publicApiUrl" .) | quote }}
{{- if not .Values.externalPostgresql.uri }}
- name: ANALYTICS_PG_DB_HOST
  value: {{ .Values.externalPostgresql.host | quote }}
- name: ANALYTICS_PG_DB_PORT
  value: {{ .Values.externalPostgresql.port | quote }}
- name: ANALYTICS_PG_DB_USERNAME
  value: {{ .Values.externalPostgresql.username | quote }}
- name: ANALYTICS_PG_DB_DATABASE
  value: {{ .Values.externalPostgresql.database | quote }}
- name: ANALYTICS_PG_DB_PASSWORD
  valueFrom:
    {{- include "kodus.pgPasswordSecretRef" . | nindent 4 }}
{{- end }}
- name: ANALYTICS_PG_DB_SCHEMA
  value: {{ .Values.config.analytics.pgSchema | quote }}
- name: ANALYTICS_PG_POOL_MAX
  value: {{ .Values.config.analytics.pgPoolMax | quote }}
{{ include "kodus.workflowEnv" . }}
{{ include "kodus.runtimeFlagsEnv" . }}
{{- end -}}

{{- define "kodus.webConfigEnv" -}}
- name: WEB_NODE_ENV
  value: {{ .Values.config.web.nodeEnv | quote }}
- name: WEB_PORT
  value: {{ .Values.web.port | quote }}
- name: WEB_PORT_API
  value: {{ .Values.api.port | quote }}
- name: WEB_HOSTNAME_API
  value: {{ include "kodus.internalApiHostname" . | quote }}
{{- /*
API_URL is the public, browser-reachable API origin. The web app's
getApiPublicUrl() is expected to prefer it over WEB_HOSTNAME_API (which must
stay in-cluster for server-side proxying) once upstream support lands; until
then it is harmless. Required for browser SSO redirects and SAML ACS URLs.
*/}}
- name: API_URL
  value: {{ include "kodus.publicApiUrl" . | quote }}
- name: NEXTAUTH_URL
  value: {{ include "kodus.publicWebUrl" . | quote }}
- name: WEB_SUPPORT_DOCS_URL
  value: {{ .Values.config.web.supportDocsUrl | quote }}
- name: WEB_SUPPORT_DISCORD_INVITE_URL
  value: {{ .Values.config.web.supportDiscordInviteUrl | quote }}
- name: WEB_SUPPORT_TALK_TO_FOUNDER_URL
  value: {{ .Values.config.web.supportTalkToFounderUrl | quote }}
{{- if .Values.global.mcpServerEnabled }}
- name: WEB_HOSTNAME_MCP_MANAGER
  value: {{ include "kodus.internalMcpManagerHostname" . | quote }}
- name: WEB_PORT_MCP_MANAGER
  value: {{ .Values.mcpManager.port | quote }}
- name: GLOBAL_MCP_MANAGER_CONTAINER_NAME
  value: {{ include "kodus.internalMcpManagerHostname" . | quote }}
{{- end }}
{{- if .Values.config.web.helpdeskHostname }}
- name: WEB_HOSTNAME_HELPDESK
  value: {{ .Values.config.web.helpdeskHostname | quote }}
{{- end }}
- name: WEB_PORT_HELPDESK
  value: {{ .Values.config.web.helpdeskPort | quote }}
- name: WEB_RULE_FILES_DOCS
  value: {{ .Values.config.web.ruleFilesDocs | quote }}
- name: WEB_TOKEN_DOCS_GITHUB
  value: {{ .Values.config.web.tokenDocs.github | quote }}
- name: WEB_TOKEN_DOCS_GITLAB
  value: {{ .Values.config.web.tokenDocs.gitlab | quote }}
- name: WEB_TOKEN_DOCS_BITBUCKET
  value: {{ .Values.config.web.tokenDocs.bitbucket | quote }}
- name: WEB_TOKEN_DOCS_AZUREREPOS
  value: {{ .Values.config.web.tokenDocs.azureRepos | quote }}
{{- if .Values.config.web.tokenDocs.forgejo }}
- name: WEB_TOKEN_DOCS_FORGEJO
  value: {{ .Values.config.web.tokenDocs.forgejo | quote }}
{{- end }}
- name: WEB_NEXTAUTH_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: nextauth-secret
- name: NEXTAUTH_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kodus.secretName" . }}
      key: nextauth-secret
{{ include "kodus.githubWebEnv" . }}
{{- end -}}
