{{- define "kodus.hookJobPodSpec" -}}
{{- $root := . -}}
serviceAccountName: {{ include "kodus.hooksServiceAccountName" $root }}
{{- $podSecurityContext := include "kodus.podSecurityContext" (dict "root" $root "component" "hooks") -}}
{{- if $podSecurityContext }}
securityContext:
{{ $podSecurityContext | nindent 2 }}
{{- end }}
{{- with $root.Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $root.Values.global.pod.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $root.Values.global.pod.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $root.Values.global.pod.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "kodus.jobEnv" -}}
{{ include "kodus.commonEnv" . }}
{{ include "kodus.backendConfigEnv" . }}
{{- end -}}
