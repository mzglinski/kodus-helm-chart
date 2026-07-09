{{- define "kodus.podSecurityContext" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- $ctx := mergeOverwrite (deepCopy ($root.Values.global.podSecurityContext | default dict)) ($cv.podSecurityContext | default dict) -}}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end -}}

{{- define "kodus.containerSecurityContext" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- $ctx := mergeOverwrite (deepCopy ($root.Values.global.securityContext | default dict)) ($cv.securityContext | default dict) -}}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end -}}

{{- define "kodus.terminationGracePeriodSeconds" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- if $cv.terminationGracePeriodSeconds -}}
{{- $cv.terminationGracePeriodSeconds -}}
{{- else if or (eq $component "worker") (eq $component "cron-worker") (eq $component "worker-analytics") (eq $component "cron-worker-analytics") -}}
{{- $root.Values.worker.terminationGracePeriodSeconds | default 660 -}}
{{- else -}}
{{- $root.Values.global.terminationGracePeriodSeconds | default 30 -}}
{{- end -}}
{{- end -}}
