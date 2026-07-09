{{- define "kodus.llmEnv" -}}
- name: API_LLM_PROVIDER_MODEL
  value: {{ .Values.llm.providerModel | quote }}
{{- if .Values.llm.openaiForceBaseUrl }}
- name: API_OPENAI_FORCE_BASE_URL
  value: {{ .Values.llm.openaiForceBaseUrl | quote }}
{{- end }}
{{- if .Values.llm.temperatureOverride }}
- name: API_LLM_TEMPERATURE_OVERRIDE
  value: {{ .Values.llm.temperatureOverride | quote }}
{{- end }}
{{- if .Values.llm.trustJsonSchemaBaseUrls }}
- name: API_TRUST_JSON_SCHEMA_BASE_URLS
  value: {{ .Values.llm.trustJsonSchemaBaseUrls | quote }}
{{- end }}
- name: API_GOOGLE_AI_PROVIDER
  value: {{ .Values.llm.google.provider | quote }}
- name: API_VERTEX_AI_LOCATION
  value: {{ .Values.llm.google.vertexLocation | quote }}
- name: API_GROQ_BASE_URL
  value: {{ .Values.llm.groq.baseUrl | quote }}
- name: API_CEREBRAS_BASE_URL
  value: {{ .Values.llm.cerebras.baseUrl | quote }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_OPEN_AI_API_KEY" "key" .Values.secrets.keys.openaiApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_ANTHROPIC_API_KEY" "key" .Values.secrets.keys.anthropicApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_GOOGLE_AI_API_KEY" "key" .Values.secrets.keys.googleAiApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "GOOGLE_GENERATIVE_AI_API_KEY" "key" .Values.secrets.keys.googleAiApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "GEMINI_API_KEY" "key" .Values.secrets.keys.geminiApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_VERTEX_AI_API_KEY" "key" .Values.secrets.keys.vertexAiApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_NOVITA_AI_API_KEY" "key" .Values.secrets.keys.novitaAiApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_MOONSHOT_API_KEY" "key" .Values.secrets.keys.moonshotApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "MOONSHOT_API_KEY" "key" .Values.secrets.keys.moonshotApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_GROQ_API_KEY" "key" .Values.secrets.keys.groqApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_CEREBRAS_API_KEY" "key" .Values.secrets.keys.cerebrasApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_OPEN_ROUTER_API_KEY" "key" .Values.secrets.keys.openRouterApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_MORPHLLM_API_KEY" "key" .Values.secrets.keys.morphllmApiKey) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_EXA_KEY" "key" .Values.secrets.keys.exaKey) }}
{{- end -}}
