{{- define "kodus.extraEnv" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $cv := include "kodus.resolveComponentValues" (dict "root" $root "component" $component) | fromYaml -}}
{{- range $root.Values.global.extraEnv }}
- name: {{ .name }}
  {{- if hasKey . "value" }}
  value: {{ .value | quote }}
  {{- else if .valueFrom }}
  valueFrom:
    {{- toYaml .valueFrom | nindent 4 }}
  {{- end }}
{{- end }}
{{- range ($cv.extraEnv | default list) }}
- name: {{ .name }}
  {{- if hasKey . "value" }}
  value: {{ .value | quote }}
  {{- else if .valueFrom }}
  valueFrom:
    {{- toYaml .valueFrom | nindent 4 }}
  {{- end }}
{{- end }}
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
