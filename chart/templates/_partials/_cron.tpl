{{- define "kodus.cronSchedule" -}}
{{- if .enabled -}}
{{- .schedule -}}
{{- else -}}
{{- .root.Values.cronRunner.disabledSchedule -}}
{{- end -}}
{{- end -}}

{{- define "kodus.cronScheduleWithSeconds" -}}
{{- if .enabled -}}
{{- .schedule -}}
{{- else -}}
{{- .root.Values.cronRunner.disabledScheduleWithSeconds -}}
{{- end -}}
{{- end -}}

{{- define "kodus.cronEnv" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $enabled := true -}}
{{- if $root.Values.cronRunner.enabled -}}
{{- if or (eq $component "cron-api") (eq $component "cron-worker") (eq $component "cron-worker-analytics") (eq $component "worker-analytics") -}}
{{- $enabled = true -}}
{{- else -}}
{{- $enabled = false -}}
{{- end -}}
{{- end -}}
- name: API_CRON_SYNC_CODE_REVIEW_REACTIONS
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.syncCodeReviewReactions) | quote }}
- name: API_CRON_KODY_LEARNING
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.kodyLearning) | quote }}
- name: API_CRON_CHECK_IF_PR_SHOULD_BE_APPROVED
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.checkIfPrShouldBeApproved) | quote }}
- name: API_CRON_ORG_REPORT
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.orgReport) | quote }}
- name: API_CRON_REPO_REPORT
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.repoReport) | quote }}
- name: API_CRON_SPEND_LIMIT_ALERT
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.spendLimitAlert) | quote }}
- name: API_CRON_STALE_REVIEW_WATCHDOG
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.staleReviewWatchdog) | quote }}
- name: API_CRON_SSO_TEST_SESSION_CLEANUP
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.ssoTestSessionCleanup) | quote }}
- name: API_CRON_CLASSIFY_ORPHANED_SESSIONS
  value: {{ include "kodus.cronScheduleWithSeconds" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.cron.classifyOrphanedSessions) | quote }}
{{- if $enabled }}
- name: KODY_RULES_DETECTOR_SWEEP_ENABLED
  value: {{ $root.Values.config.cron.kodyRulesDetectorSweepEnabled | quote }}
{{- else }}
- name: KODY_RULES_DETECTOR_SWEEP_ENABLED
  value: "false"
{{- end }}
- name: ANALYTICS_INGESTION_CRON
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.analytics.ingestionCron) | quote }}
- name: ANALYTICS_INGESTION_DISABLED
  value: {{ ternary $root.Values.config.analytics.ingestionDisabled true (not $enabled) | quote }}
- name: ANALYTICS_INGESTION_RUN_ON_BOOT
  value: {{ ternary $root.Values.config.analytics.ingestionRunOnBoot false (not $enabled) | quote }}
- name: ANALYTICS_CLASSIFIER_CRON
  value: {{ include "kodus.cronSchedule" (dict "root" $root "enabled" $enabled "schedule" $root.Values.config.analytics.classifierCron) | quote }}
- name: ANALYTICS_CLASSIFIER_DISABLED
  value: {{ ternary $root.Values.config.analytics.classifierDisabled true (not $enabled) | quote }}
{{- end -}}
