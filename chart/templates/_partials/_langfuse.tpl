{{- define "kodus.langfuseEnv" -}}
- name: LANGFUSE_TRACING
  value: {{ .Values.langfuse.enabled | quote }}
{{- if .Values.langfuse.publicKey }}
- name: LANGFUSE_PUBLIC_KEY
  value: {{ .Values.langfuse.publicKey | quote }}
{{- end }}
{{- if .Values.langfuse.baseUrl }}
- name: LANGFUSE_BASE_URL
  value: {{ .Values.langfuse.baseUrl | quote }}
{{- end }}
{{- if .Values.langfuse.environment }}
- name: LANGFUSE_ENVIRONMENT
  value: {{ .Values.langfuse.environment | quote }}
{{- end }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "LANGFUSE_SECRET_KEY" "key" .Values.secrets.keys.langfuseSecretKey) }}
{{- end -}}
