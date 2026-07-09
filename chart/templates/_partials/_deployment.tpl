{{- define "kodus.deploymentPodSpec" -}}
{{- $root := .root -}}
{{- $component := .component -}}
serviceAccountName: {{ include "kodus.serviceAccountName" $root }}
terminationGracePeriodSeconds: {{ include "kodus.terminationGracePeriodSeconds" (dict "root" $root "component" $component) }}
{{- $podSecurityContext := include "kodus.podSecurityContext" (dict "root" $root "component" $component) -}}
{{- if $podSecurityContext }}
securityContext:
{{ $podSecurityContext | nindent 2 }}
{{- end }}
{{- with $root.Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- $nodeSelector := include "kodus.podNodeSelector" (dict "root" $root "component" $component) -}}
{{- if $nodeSelector }}
nodeSelector:
{{ $nodeSelector | nindent 2 }}
{{- end }}
{{- $affinity := include "kodus.podAffinity" (dict "root" $root "component" $component) -}}
{{- if $affinity }}
affinity:
{{ $affinity | nindent 2 }}
{{- end }}
{{- $tolerations := include "kodus.podTolerations" (dict "root" $root "component" $component) -}}
{{- if $tolerations }}
tolerations:
{{ $tolerations | nindent 2 }}
{{- end }}
{{- $topology := include "kodus.podTopologySpreadConstraints" (dict "root" $root "component" $component) -}}
{{- if $topology }}
topologySpreadConstraints:
{{ $topology | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "kodus.deploymentPodMetadata" -}}
{{- $root := .root -}}
{{- $component := .component -}}
labels:
  {{- include "kodus.componentSelectorLabels" (dict "root" $root "component" $component) | nindent 2 }}
{{- $labels := include "kodus.podLabels" (dict "root" $root "component" $component) -}}
{{- if $labels }}
{{ $labels | nindent 2 }}
{{- end }}
{{- $annotations := include "kodus.podAnnotations" (dict "root" $root "component" $component) -}}
{{- if $annotations }}
annotations:
{{ $annotations | nindent 2 }}
{{- end }}
{{- end -}}
