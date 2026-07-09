{{- define "kodus.githubWebOAuthClientId" -}}
{{- default .Values.config.github.clientId .Values.config.github.webOAuthClientId -}}
{{- end -}}

{{- define "kodus.githubApiEnv" -}}
{{- if .Values.config.github.appId }}
- name: API_GITHUB_APP_ID
  value: {{ .Values.config.github.appId | quote }}
{{- end }}
{{- if .Values.config.github.clientId }}
- name: GLOBAL_GITHUB_CLIENT_ID
  value: {{ .Values.config.github.clientId | quote }}
{{- end }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_GITHUB_CLIENT_SECRET" "key" .Values.secrets.keys.githubAppClientSecret) }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "API_GITHUB_PRIVATE_KEY" "key" .Values.secrets.keys.githubAppPrivateKey) }}
{{- end -}}

{{- define "kodus.githubWebEnv" -}}
{{- if .Values.config.github.installUrl }}
- name: WEB_GITHUB_INSTALL_URL
  value: {{ .Values.config.github.installUrl | quote }}
{{- end }}
{{- $webOAuthClientId := include "kodus.githubWebOAuthClientId" . -}}
{{- if $webOAuthClientId }}
- name: WEB_OAUTH_GITHUB_CLIENT_ID
  value: {{ $webOAuthClientId | quote }}
{{- end }}
{{ include "kodus.optionalSecretEnv" (dict "root" . "name" "WEB_OAUTH_GITHUB_CLIENT_SECRET" "key" (default .Values.secrets.keys.githubAppClientSecret .Values.secrets.keys.webOAuthGithubClientSecret)) }}
{{- end -}}
