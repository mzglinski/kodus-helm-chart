{{- define "kodus.isSetUtilizationPercentage" -}}
{{- $v := . -}}
{{- if kindIs "string" $v -}}
{{- if and (ne $v "") (regexMatch `^[0-9]+(\.[0-9]+)?$` $v) -}}true{{- end -}}
{{- else if or (kindIs "int" $v) (kindIs "float64" $v) (kindIs "int64" $v) -}}
true
{{- end -}}
{{- end -}}

{{- define "kodus.utilizationPercentageValue" -}}
{{- $v := . -}}
{{- if kindIs "string" $v -}}
{{- int $v -}}
{{- else -}}
{{- $v -}}
{{- end -}}
{{- end -}}

{{- define "kodus.componentMinReplicas" -}}
{{- $values := .values -}}
{{- if and $values.autoscaling $values.autoscaling.enabled -}}
{{- $values.autoscaling.minReplicas | default $values.replicaCount -}}
{{- else -}}
{{- $values.replicaCount -}}
{{- end -}}
{{- end -}}

{{- define "kodus.autoscalingHasResourceMetric" -}}
{{- $as := . -}}
{{- or (include "kodus.isSetUtilizationPercentage" $as.targetCPUUtilizationPercentage) (include "kodus.isSetUtilizationPercentage" $as.targetMemoryUtilizationPercentage) -}}
{{- end -}}

{{- define "kodus.validateAutoscaling" -}}
{{- range $component := list "api" "worker" "webhooks" "web" }}
{{- $values := index $.Values $component }}
{{- if and $values.enabled $values.autoscaling.enabled }}
{{- if not (include "kodus.autoscalingHasResourceMetric" $values.autoscaling) }}
{{- fail (printf "%s.autoscaling.enabled requires targetCPUUtilizationPercentage and/or targetMemoryUtilizationPercentage" $component) }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "kodus.hpa" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $values := .values -}}
{{- $minReplicas := include "kodus.componentMinReplicas" (dict "values" $values) | int -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "kodus.fullname" $root }}-{{ $component }}
  labels:
    {{- include "kodus.labels" $root | nindent 4 }}
    app.kubernetes.io/component: {{ $component }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "kodus.fullname" $root }}-{{ $component }}
  minReplicas: {{ $minReplicas }}
  maxReplicas: {{ $values.autoscaling.maxReplicas | default 10 }}
  metrics:
    {{- if include "kodus.isSetUtilizationPercentage" $values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ include "kodus.utilizationPercentageValue" $values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if include "kodus.isSetUtilizationPercentage" $values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ include "kodus.utilizationPercentageValue" $values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
  {{- with $values.autoscaling.behavior }}
  behavior:
    {{- toYaml . | nindent 4 }}
  {{- else }}
  behavior:
    scaleUp:
      stabilizationWindowSeconds: {{ $values.autoscaling.stabilizationWindowSeconds | default 0 }}
  {{- end }}
{{- end -}}
