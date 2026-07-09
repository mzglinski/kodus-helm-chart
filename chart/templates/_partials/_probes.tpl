{{- define "kodus.apiProbes" -}}
livenessProbe:
  httpGet:
    path: /health/live
    port: http
  initialDelaySeconds: 60
  periodSeconds: 15
readinessProbe:
  httpGet:
    path: /health/ready
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
{{- end -}}

{{- define "kodus.webhooksProbes" -}}
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 60
  periodSeconds: 15
readinessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
{{- end -}}

{{- define "kodus.workerHealthPort" -}}
{{- .Values.worker.healthPort | default 3334 -}}
{{- end -}}

{{- define "kodus.workerProbes" -}}
ports:
  - name: health
    containerPort: {{ include "kodus.workerHealthPort" . | int }}
    protocol: TCP
livenessProbe:
  httpGet:
    path: /health
    port: health
  initialDelaySeconds: 90
  periodSeconds: 15
readinessProbe:
  httpGet:
    path: /health
    port: health
  initialDelaySeconds: 60
  periodSeconds: 10
{{- end -}}
