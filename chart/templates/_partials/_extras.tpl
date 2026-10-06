{{/*
Values path for a workload's extraEnv list (error messages and docs).
*/}}
{{- define "kodus.extraEnvValuesPath" -}}
{{- if eq . "worker-analytics" -}}workerAnalytics
{{- else if eq . "mcp-manager" -}}mcpManager
{{- else if eq . "cron-api" -}}cronRunner.api
{{- else if eq . "cron-worker" -}}cronRunner.worker
{{- else if eq . "cron-worker-analytics" -}}cronRunner.workerAnalytics
{{- else if eq . "migrations" -}}jobs.migrations
{{- else if eq . "seeds" -}}jobs.seeds
{{- else -}}{{ . }}
{{- end -}}
{{- end -}}

{{/*
Fail when an extraEnv list is not a sequence of EnvVar objects.
*/}}
{{- define "kodus.validateEnvList" -}}
{{- $scope := .scope -}}
{{- $vars := .vars | default list -}}
{{- if not (kindIs "slice" $vars) -}}
{{- fail (printf "%s must be a list of {name, value} or {name, valueFrom} entries" $scope) -}}
{{- end -}}
{{- range $i, $env := $vars -}}
{{- if not (kindIs "map" $env) -}}
{{- fail (printf "%s[%v] must be an object with name and value or valueFrom" $scope $i) -}}
{{- end -}}
{{- $name := $env.name | default "" -}}
{{- if not $name -}}
{{- fail (printf "%s[%v] requires name" $scope $i) -}}
{{- end -}}
{{- $hasValue := and (hasKey $env "value") (not (kindIs "invalid" $env.value)) -}}
{{- if and (not $hasValue) (not $env.valueFrom) -}}
{{- fail (printf "%s[%v] (%s) requires value or valueFrom" $scope $i $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render one EnvVar. value wins when both value and valueFrom are set.
Empty string, false, and 0 are kept; a null value falls through to valueFrom.
*/}}
{{- define "kodus.renderEnvVar" -}}
- name: {{ .name }}
{{- if and (hasKey . "value") (not (kindIs "invalid" .value)) }}
  value: {{ .value | quote }}
{{- else }}
  valueFrom:
    {{- toYaml .valueFrom | nindent 4 }}
{{- end }}
{{- end -}}

{{/*
Container env appended after chart-managed variables.
global.extraEnv applies to every workload; <component>.extraEnv applies to that
workload only. The component entry replaces a global entry with the same name.
*/}}
{{- define "kodus.extraEnv" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- $global := $root.Values.global.extraEnv | default list -}}
{{- $local := $cv.extraEnv | default list -}}
{{- include "kodus.validateEnvList" (dict "scope" "global.extraEnv" "vars" $global) -}}
{{- include "kodus.validateEnvList" (dict "scope" (printf "%s.extraEnv" (include "kodus.extraEnvValuesPath" $component)) "vars" $local) -}}
{{- $all := concat $global $local -}}
{{- $last := dict -}}
{{- range $i, $env := $all -}}
{{- $last = set $last ($env.name | toString) $i -}}
{{- end -}}
{{- $lines := list -}}
{{- range $i, $env := $all -}}
{{- if eq (toString (index $last ($env.name | toString))) (toString $i) -}}
{{- $lines = append $lines (include "kodus.renderEnvVar" $env | trim) -}}
{{- end -}}
{{- end -}}
{{- if $lines -}}
{{ join "\n" $lines | nindent 12 }}
{{- end -}}
{{- end -}}

{{- define "kodus.extraVolumes" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- $global := $root.Values.global.extraVolumes | default list -}}
{{- $local := $cv.extraVolumes | default list -}}
{{- if or $global $local }}
{{- concat $global $local | toYaml }}
{{- end }}
{{- end -}}

{{- define "kodus.extraVolumeMounts" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- $global := $root.Values.global.extraVolumeMounts | default list -}}
{{- $local := $cv.extraVolumeMounts | default list -}}
{{- if or $global $local }}
{{- concat $global $local | toYaml }}
{{- end }}
{{- end -}}
