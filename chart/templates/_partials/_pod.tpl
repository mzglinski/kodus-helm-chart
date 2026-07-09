{{- define "kodus.resolveComponentValues" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := dict -}}
{{- if hasKey $root.Values $component -}}
{{- $cv = index $root.Values $component -}}
{{- else if eq $component "worker-analytics" -}}
{{- $cv = $root.Values.workerAnalytics -}}
{{- else if eq $component "cron-api" -}}
{{- $cv = $root.Values.cronRunner.api -}}
{{- else if eq $component "cron-worker" -}}
{{- $cv = $root.Values.cronRunner.worker -}}
{{- else if eq $component "cron-worker-analytics" -}}
{{- $cv = $root.Values.cronRunner.workerAnalytics -}}
{{- else if eq $component "mcp-manager" -}}
{{- $cv = $root.Values.mcpManager -}}
{{- end -}}
{{- $cv | toYaml -}}
{{- end -}}

{{- define "kodus.podLabels" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- with $cv.podLabels }}
{{- toYaml . }}
{{- end }}
{{- with $root.Values.global.pod.labels }}
{{- toYaml . }}
{{- end }}
{{- end -}}

{{- define "kodus.podAnnotations" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- with $cv.podAnnotations }}
{{- toYaml . }}
{{- end }}
{{- with $root.Values.global.pod.annotations }}
{{- toYaml . }}
{{- end }}
{{- end -}}

{{- define "kodus.podNodeSelector" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- if $cv.nodeSelector }}
{{- toYaml $cv.nodeSelector | nindent 0 }}
{{- else if $root.Values.global.pod.nodeSelector }}
{{- toYaml $root.Values.global.pod.nodeSelector | nindent 0 }}
{{- end }}
{{- end -}}

{{- define "kodus.podTolerations" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- if $cv.tolerations }}
{{- toYaml $cv.tolerations | nindent 0 }}
{{- else if $root.Values.global.pod.tolerations }}
{{- toYaml $root.Values.global.pod.tolerations | nindent 0 }}
{{- end }}
{{- end -}}

{{- define "kodus.podAffinity" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- if $cv.affinity }}
{{- toYaml $cv.affinity | nindent 0 }}
{{- else if $root.Values.global.pod.affinity }}
{{- toYaml $root.Values.global.pod.affinity | nindent 0 }}
{{- end }}
{{- end -}}

{{- define "kodus.podTopologySpreadConstraints" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- if $cv.topologySpreadConstraints }}
{{- toYaml $cv.topologySpreadConstraints | nindent 0 }}
{{- else if $root.Values.global.pod.topologySpreadConstraints }}
{{- toYaml $root.Values.global.pod.topologySpreadConstraints | nindent 0 }}
{{- end }}
{{- end -}}
