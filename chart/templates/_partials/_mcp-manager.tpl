{{- define "kodus.internalMcpManagerHostname" -}}
{{- if .Values.web.mcpManagerHostname -}}
{{- .Values.web.mcpManagerHostname -}}
{{- else -}}
{{- printf "%s-mcp-manager" (include "kodus.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "kodus.internalMcpManagerUrl" -}}
{{- printf "http://%s:%v" (include "kodus.internalMcpManagerHostname" .) .Values.mcpManager.port -}}
{{- end -}}

{{- define "kodus.mcpManagerPublicRedirectUri" -}}
{{- if .Values.mcpManager.redirectUri -}}
{{- .Values.mcpManager.redirectUri -}}
{{- else -}}
{{- printf "%s/setup/mcp/oauth" (include "kodus.publicWebUrl" .) -}}
{{- end -}}
{{- end -}}

{{- define "kodus.mcpManagerEnv" -}}
- name: NODE_ENV
  value: {{ .Values.mcpManager.nodeEnv | quote }}
- name: API_MCP_MANAGER_NODE_ENV
  value: {{ .Values.mcpManager.nodeEnv | quote }}
- name: API_MCP_MANAGER_DATABASE_ENV
  value: {{ .Values.mcpManager.databaseEnv | quote }}
- name: API_MCP_MANAGER_LOG_LEVEL
  value: {{ .Values.mcpManager.logLevel | quote }}
- name: API_MCP_MANAGER_PORT
  value: {{ .Values.mcpManager.port | quote }}
- name: API_MCP_MANAGER_CORS_ORIGINS
  value: {{ .Values.mcpManager.corsOrigins | quote }}
- name: API_MCP_MANAGER_MCP_PROVIDERS
  value: {{ .Values.mcpManager.mcpProviders | quote }}
- name: API_MCP_MANAGER_PG_DB_SCHEMA
  value: {{ .Values.mcpManager.pgSchema | quote }}
- name: API_MCP_MANAGER_COMPOSIO_BASE_URL
  value: {{ .Values.mcpManager.composioBaseUrl | quote }}
- name: API_MCP_MANAGER_REDIRECT_URI
  value: {{ include "kodus.mcpManagerPublicRedirectUri" . | quote }}
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
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_MCP_MANAGER_COMPOSIO_API_KEY" "key" .Values.secrets.keys.mcpManagerComposioApiKey) }}
{{ include "kodus.mcpApiEnv" . }}
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
{{- end -}}
