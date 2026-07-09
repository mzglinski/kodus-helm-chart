# kodus

Helm chart for self-hosted Kodus AI (stateless components only)

## Prerequisites

External PostgreSQL (with pgvector), MongoDB 8.x, and RabbitMQ (with `rabbitmq_delayed_message_exchange` plugin) are required.

## Resources

The chart does not ship CPU/memory requests or limits — set `<component>.resources` (and `jobs.*.resources` for hook Jobs) for your cluster and workload. Tools such as [KRR](https://github.com/robusta-dev/krr) can help derive starting values from live usage. Requests are required when using HPA resource metrics.

## Secrets

Set `secrets.existingSecret` to a pre-provisioned Secret for production. When empty, a **pre-install/pre-upgrade** hook generates installer-compatible secrets (see [kodus-installer `schema-vars.sh`](https://github.com/kodustech/kodus-installer/blob/main/scripts/schema-vars.sh)), preserves existing keys on upgrade via `lookup`, and keeps the Secret across releases (`helm.sh/resource-policy: keep`). With `helm template` or Argo CD dry-run, `lookup` returns empty and the hook manifest shows freshly generated values.

Database **URI mode** (`externalPostgresql.uri`, `externalMongodb.uri`, `externalRabbitmq.uri`) stores connection strings in the app Secret (`pg-uri`, `mongo-uri`, `rabbitmq-uri`) and wires pods via `secretKeyRef`. When `secrets.existingSecret` is set, add those keys to your Secret manually. RabbitMQ credentials can alternatively live in `externalRabbitmq.existingSecret` (`usernameKey` / `passwordKey`); the hook builds `rabbitmq-uri`.

`externalPostgresql.uri` is incompatible with `jobs.migrations` and analytics workers: the analytics warehouse has no URL env var and requires discrete `API_PG_DB_*` fields — use host/port/username/database instead.

MongoDB `authSource` is emitted as `API_MG_DB_PRODUCTION_CONFIG` (`?authSource=…`), matching `MongooseFactory` production URI assembly.

## Service ports

Container/service ports (`api.port`, `webhooks.port`) are the single source of truth for `API_PORT` / `API_WEBHOOKS_PORT` / `WEB_PORT_API` — do not duplicate them under `config.*`.

## Database migrations and seeds

Migrations and seeds run as **pre-install/pre-upgrade hook Jobs** (`jobs.migrations`, `jobs.seeds`) before Deployments roll out; application pods never migrate on boot.

## Service accounts

`serviceAccount.create` defaults to `false` — workloads and hook jobs use the namespace `default` account. Set `serviceAccount.name` and/or `serviceAccount.hooks.name` to use pre-existing accounts. To create chart-managed accounts, set `serviceAccount.create: true`; add `serviceAccount.hooks.create: true` for a separate hook SA (created as a pre-upgrade hook before migrations, `{release}-hooks` by default).

## Scheduled jobs (crons)

Kodus uses NestJS `@Cron` inside the **api**, **worker**, and **webhooks** processes. By default crons run in those Deployments (`cronRunner.enabled: false`).

Set `cronRunner.enabled: true` when `api` / `worker` / `webhooks` run with more than one replica (fixed `replicaCount` or HPA `minReplicas` > 1): the chart adds single-replica **cron-api** and **cron-worker** pods with real schedules, and gives HA pods leap-day expressions (`0 0 29 2 *`) so jobs do not duplicate. Many jobs also use Postgres advisory locks, but coverage is not complete.

## Ingress (nginx)

When using the bundled nginx ingress class, default annotations raise proxy buffer sizes for NextAuth session cookies (`Set-Cookie` response headers can exceed nginx’s 4k default). Override `ingress.annotations` if your controller uses different keys.

For TLS automation with cert-manager, add annotations such as `kubernetes.io/tls-acme: "true"` and `cert-manager.io/cluster-issuer: <issuer>` — they are documented in `values.yaml` but not enabled by default.

API ingress paths are gated on `api.enabled` and `webhooks.enabled` so disabled components are not routed.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| api.affinity | object | `{}` |  |
| api.autoscaling.enabled | bool | `false` |  |
| api.autoscaling.maxReplicas | int | `10` |  |
| api.autoscaling.minReplicas | string | `nil` |  |
| api.autoscaling.stabilizationWindowSeconds | int | `0` |  |
| api.enabled | bool | `true` |  |
| api.nodeSelector | object | `{}` |  |
| api.podAnnotations | object | `{}` |  |
| api.podDisruptionBudget.enabled | bool | `false` |  |
| api.podDisruptionBudget.minAvailable | int | `1` |  |
| api.podLabels | object | `{}` |  |
| api.port | int | `3001` |  |
| api.replicaCount | int | `1` |  |
| api.resources | object | `{}` |  |
| api.tolerations | list | `[]` |  |
| api.topologySpreadConstraints | list | `[]` |  |
| config.agentReviewEnabled | bool | `true` |  |
| config.analytics.classifierCron | string | `"*/15 * * * *"` |  |
| config.analytics.classifierDisabled | bool | `false` |  |
| config.analytics.ingestionCron | string | `"*/30 * * * *"` |  |
| config.analytics.ingestionDisabled | bool | `false` |  |
| config.analytics.ingestionRunOnBoot | bool | `true` |  |
| config.analytics.pgPoolMax | int | `5` |  |
| config.analytics.pgSchema | string | `"analytics"` |  |
| config.cron.checkIfPrShouldBeApproved | string | `"*/2 * * * *"` |  |
| config.cron.classifyOrphanedSessions | string | `"0 */15 * * * *"` |  |
| config.cron.kodyLearning | string | `"0 0 * * 6"` |  |
| config.cron.kodyRulesDetectorSweepEnabled | bool | `true` |  |
| config.cron.orgReport | string | `"0 9 1 * *"` |  |
| config.cron.repoReport | string | `"0 9 1,16 * *"` |  |
| config.cron.spendLimitAlert | string | `"0 * * * *"` |  |
| config.cron.ssoTestSessionCleanup | string | `"0 1 * * *"` |  |
| config.cron.staleReviewWatchdog | string | `"*/30 * * * *"` |  |
| config.cron.syncCodeReviewReactions | string | `"0 0 * * *"` |  |
| config.developmentMode | bool | `false` |  |
| config.docs.basicUser | string | `""` |  |
| config.docs.enabled | bool | `false` |  |
| config.docs.path | string | `"/docs"` |  |
| config.docs.specPath | string | `"/openapi.json"` |  |
| config.email.provider | string | `"resend"` |  |
| config.email.smtp.from | string | `"noreply@notifications.kodus.io"` |  |
| config.email.smtp.host | string | `""` |  |
| config.email.smtp.port | int | `587` |  |
| config.email.smtp.secure | string | `""` |  |
| config.email.smtp.user | string | `""` |  |
| config.email.userInviteBaseUrl | string | `""` |  |
| config.github.appId | string | `""` |  |
| config.github.clientId | string | `""` |  |
| config.github.installUrl | string | `""` |  |
| config.github.webOAuthClientId | string | `""` |  |
| config.globalApiContainerName | string | `"kodus_api"` |  |
| config.jwtExpiresIn | string | `"365d"` |  |
| config.jwtRefreshExpiresIn | string | `"7d"` |  |
| config.rabbitmqWait | bool | `true` |  |
| config.rateInterval | int | `1000` |  |
| config.rateMaxRequest | int | `100` |  |
| config.sandbox.provider | string | `"local"` |  |
| config.web.helpdeskHostname | string | `""` |  |
| config.web.helpdeskPort | int | `3004` |  |
| config.web.nodeEnv | string | `"self-hosted"` |  |
| config.web.ruleFilesDocs | string | `"https://docs.kodus.io/how_to_use/en/code_review/configs/rules_file_detection"` |  |
| config.web.supportDiscordInviteUrl | string | `"https://discord.gg/QFzwwmNmdN"` |  |
| config.web.supportDocsUrl | string | `"https://docs.kodus.io"` |  |
| config.web.supportTalkToFounderUrl | string | `"https://cal.com/gabrielmalinosqui/30min"` |  |
| config.web.tokenDocs.azureRepos | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/azure_devops_pat"` |  |
| config.web.tokenDocs.bitbucket | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/bitbucket_pat"` |  |
| config.web.tokenDocs.forgejo | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/forgejo_pat"` |  |
| config.web.tokenDocs.github | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/github_pat"` |  |
| config.web.tokenDocs.gitlab | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/gitlab_pat"` |  |
| config.workerDrainTimeoutMs | int | `600000` |  |
| config.workflow.codeReviewPrefetch | int | `20` |  |
| config.workflow.codeReviewProcessTimeoutMs | int | `7200000` |  |
| config.workflow.outboxMaxAttempts | int | `10` |  |
| config.workflow.publisherPrefetch | int | `5` |  |
| config.workflow.webhookPrefetch | int | `20` |  |
| config.workflow.webhookProcessTimeoutMs | int | `600000` |  |
| config.workflow.workerPrefetch | int | `20` |  |
| cronRunner.api.enabled | bool | `true` |  |
| cronRunner.api.replicaCount | int | `1` |  |
| cronRunner.api.resources | object | `{}` |  |
| cronRunner.disabledSchedule | string | `"0 0 29 2 *"` |  |
| cronRunner.disabledScheduleWithSeconds | string | `"0 0 0 29 2 *"` |  |
| cronRunner.enabled | bool | `false` |  |
| cronRunner.worker.enabled | bool | `true` |  |
| cronRunner.worker.replicaCount | int | `1` |  |
| cronRunner.worker.resources | object | `{}` |  |
| cronRunner.worker.role | string | `"code-review"` |  |
| cronRunner.workerAnalytics.enabled | bool | `false` |  |
| cronRunner.workerAnalytics.replicaCount | int | `1` |  |
| cronRunner.workerAnalytics.resources | object | `{}` |  |
| cronRunner.workerAnalytics.role | string | `"analytics"` |  |
| externalMongodb.authSource | string | `"admin"` |  |
| externalMongodb.database | string | `"kodus"` |  |
| externalMongodb.existingSecret | string | `""` |  |
| externalMongodb.host | string | `""` |  |
| externalMongodb.passwordKey | string | `"mongo-password"` |  |
| externalMongodb.port | int | `27017` |  |
| externalMongodb.uri | string | `""` |  |
| externalMongodb.username | string | `"kodus"` |  |
| externalPostgresql.database | string | `"kodus_db"` |  |
| externalPostgresql.existingSecret | string | `""` |  |
| externalPostgresql.host | string | `""` |  |
| externalPostgresql.passwordKey | string | `"password"` |  |
| externalPostgresql.port | int | `5432` |  |
| externalPostgresql.uri | string | `""` |  |
| externalPostgresql.username | string | `"kodus"` |  |
| externalRabbitmq.existingSecret | string | `""` |  |
| externalRabbitmq.host | string | `""` |  |
| externalRabbitmq.password | string | `""` |  |
| externalRabbitmq.passwordKey | string | `"password"` |  |
| externalRabbitmq.port | int | `5672` |  |
| externalRabbitmq.uri | string | `""` |  |
| externalRabbitmq.username | string | `""` |  |
| externalRabbitmq.usernameKey | string | `"username"` |  |
| externalRabbitmq.vhost | string | `"kodus-ai"` |  |
| fullnameOverride | string | `""` |  |
| global.betaFeatures | bool | `false` |  |
| global.databaseDisableSsl | bool | `true` |  |
| global.databaseEnv | string | `"production"` |  |
| global.extraEnv | list | `[]` |  |
| global.extraVolumeMounts | list | `[]` |  |
| global.extraVolumes | list | `[]` |  |
| global.logLevel | string | `"error"` |  |
| global.logPretty | bool | `false` |  |
| global.mcpServerEnabled | bool | `false` |  |
| global.nodeEnv | string | `"production"` |  |
| global.pod.affinity | object | `{}` |  |
| global.pod.annotations | object | `{}` |  |
| global.pod.labels | object | `{}` |  |
| global.pod.nodeSelector | object | `{}` |  |
| global.pod.tolerations | list | `[]` |  |
| global.pod.topologySpreadConstraints | list | `[]` |  |
| global.podSecurityContext.fsGroup | int | `1000` |  |
| global.podSecurityContext.runAsGroup | int | `1000` |  |
| global.podSecurityContext.runAsNonRoot | bool | `true` |  |
| global.podSecurityContext.runAsUser | int | `1000` |  |
| global.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| global.rabbitmqEnabled | bool | `true` |  |
| global.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| global.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| global.securityContext.readOnlyRootFilesystem | bool | `false` |  |
| global.telemetryDisabled | bool | `true` |  |
| global.telemetryEndpoint | string | `""` |  |
| global.terminationGracePeriodSeconds | int | `30` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"ghcr.io/kodustech"` |  |
| image.tag | string | `"2.1.24"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/large-client-header-buffers" | string | `"4 32k"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-buffer-size" | string | `"128k"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-buffers-number" | string | `"4"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-busy-buffers-size" | string | `"256k"` |  |
| ingress.api.enabled | bool | `true` |  |
| ingress.api.hostname | string | `""` |  |
| ingress.api.secretName | string | `""` |  |
| ingress.api.tls | bool | `true` |  |
| ingress.api.webhookPaths[0] | string | `"/github/webhook"` |  |
| ingress.api.webhookPaths[1] | string | `"/gitlab/webhook"` |  |
| ingress.api.webhookPaths[2] | string | `"/bitbucket/webhook"` |  |
| ingress.api.webhookPaths[3] | string | `"/azure-repos/webhook"` |  |
| ingress.api.webhookPaths[4] | string | `"/forgejo/webhook"` |  |
| ingress.className | string | `"nginx"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.web.enabled | bool | `true` |  |
| ingress.web.hostname | string | `""` |  |
| ingress.web.secretName | string | `""` |  |
| ingress.web.tls | bool | `true` |  |
| jobs.migrations.activeDeadlineSeconds | int | `1800` |  |
| jobs.migrations.backoffLimit | int | `3` |  |
| jobs.migrations.enabled | bool | `true` |  |
| jobs.migrations.resources | object | `{}` |  |
| jobs.seeds.activeDeadlineSeconds | int | `600` |  |
| jobs.seeds.backoffLimit | int | `3` |  |
| jobs.seeds.enabled | bool | `true` |  |
| jobs.seeds.resources | object | `{}` |  |
| llm.cerebras.baseUrl | string | `"https://api.cerebras.ai/v1"` |  |
| llm.google.provider | string | `"gemini"` |  |
| llm.google.vertexLocation | string | `"us-central1"` |  |
| llm.groq.baseUrl | string | `"https://api.groq.com/openai/v1"` |  |
| llm.openaiForceBaseUrl | string | `""` |  |
| llm.providerModel | string | `"auto"` |  |
| llm.temperatureOverride | string | `""` |  |
| llm.trustJsonSchemaBaseUrls | string | `""` |  |
| mcpManager.affinity | object | `{}` |  |
| mcpManager.composioBaseUrl | string | `"https://backend.composio.dev/api/v3"` |  |
| mcpManager.corsOrigins | string | `"*"` |  |
| mcpManager.databaseEnv | string | `"production"` |  |
| mcpManager.enabled | bool | `true` |  |
| mcpManager.logLevel | string | `"info"` |  |
| mcpManager.mcpProviders | string | `"kodusmcp,composio,custom"` |  |
| mcpManager.nodeEnv | string | `"production"` |  |
| mcpManager.nodeSelector | object | `{}` |  |
| mcpManager.pgSchema | string | `"mcp-manager"` |  |
| mcpManager.podAnnotations | object | `{}` |  |
| mcpManager.podLabels | object | `{}` |  |
| mcpManager.port | int | `3101` |  |
| mcpManager.redirectUri | string | `""` |  |
| mcpManager.replicaCount | int | `1` |  |
| mcpManager.resources | object | `{}` |  |
| mcpManager.tolerations | list | `[]` |  |
| mcpManager.topologySpreadConstraints | list | `[]` |  |
| nameOverride | string | `""` |  |
| publicUrls.api | string | `""` |  |
| publicUrls.web | string | `""` |  |
| secrets.existingSecret | string | `""` |  |
| secrets.keys.anthropicApiKey | string | `"anthropic-api-key"` |  |
| secrets.keys.apiDocsBasicPass | string | `"api-docs-basic-pass"` |  |
| secrets.keys.cerebrasApiKey | string | `"cerebras-api-key"` |  |
| secrets.keys.e2bKey | string | `"e2b-key"` |  |
| secrets.keys.exaKey | string | `"exa-key"` |  |
| secrets.keys.geminiApiKey | string | `"gemini-api-key"` |  |
| secrets.keys.githubAppClientSecret | string | `"github-app-client-secret"` |  |
| secrets.keys.githubAppPrivateKey | string | `"github-app-private-key"` |  |
| secrets.keys.googleAiApiKey | string | `"google-ai-api-key"` |  |
| secrets.keys.groqApiKey | string | `"groq-api-key"` |  |
| secrets.keys.mcpManagerComposioApiKey | string | `"mcp-manager-composio-api-key"` |  |
| secrets.keys.moonshotApiKey | string | `"moonshot-api-key"` |  |
| secrets.keys.morphllmApiKey | string | `"morphllm-api-key"` |  |
| secrets.keys.novitaAiApiKey | string | `"novita-ai-api-key"` |  |
| secrets.keys.openRouterApiKey | string | `"open-router-api-key"` |  |
| secrets.keys.openaiApiKey | string | `"openai-api-key"` |  |
| secrets.keys.resendApiKey | string | `"resend-api-key"` |  |
| secrets.keys.smtpPass | string | `"smtp-pass"` |  |
| secrets.keys.vertexAiApiKey | string | `"vertex-ai-api-key"` |  |
| secrets.keys.webOAuthGithubClientSecret | string | `"web-oauth-github-client-secret"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.hooks.annotations | object | `{}` |  |
| serviceAccount.hooks.create | bool | `false` |  |
| serviceAccount.hooks.name | string | `""` |  |
| serviceAccount.name | string | `""` |  |
| web.affinity | object | `{}` |  |
| web.apiHostname | string | `""` |  |
| web.autoscaling.enabled | bool | `false` |  |
| web.autoscaling.maxReplicas | int | `10` |  |
| web.autoscaling.minReplicas | string | `nil` |  |
| web.autoscaling.stabilizationWindowSeconds | int | `0` |  |
| web.enabled | bool | `true` |  |
| web.mcpManagerHostname | string | `""` |  |
| web.nodeSelector | object | `{}` |  |
| web.podAnnotations | object | `{}` |  |
| web.podDisruptionBudget.enabled | bool | `false` |  |
| web.podDisruptionBudget.minAvailable | int | `1` |  |
| web.podLabels | object | `{}` |  |
| web.port | int | `3000` |  |
| web.replicaCount | int | `1` |  |
| web.resources | object | `{}` |  |
| web.tolerations | list | `[]` |  |
| web.topologySpreadConstraints | list | `[]` |  |
| webhooks.affinity | object | `{}` |  |
| webhooks.autoscaling.enabled | bool | `false` |  |
| webhooks.autoscaling.maxReplicas | int | `10` |  |
| webhooks.autoscaling.minReplicas | string | `nil` |  |
| webhooks.autoscaling.stabilizationWindowSeconds | int | `0` |  |
| webhooks.enabled | bool | `true` |  |
| webhooks.nodeSelector | object | `{}` |  |
| webhooks.podAnnotations | object | `{}` |  |
| webhooks.podDisruptionBudget.enabled | bool | `false` |  |
| webhooks.podDisruptionBudget.minAvailable | int | `1` |  |
| webhooks.podLabels | object | `{}` |  |
| webhooks.port | int | `3332` |  |
| webhooks.replicaCount | int | `1` |  |
| webhooks.resources | object | `{}` |  |
| webhooks.tolerations | list | `[]` |  |
| webhooks.topologySpreadConstraints | list | `[]` |  |
| worker.affinity | object | `{}` |  |
| worker.autoscaling.enabled | bool | `false` |  |
| worker.autoscaling.maxReplicas | int | `10` |  |
| worker.autoscaling.minReplicas | string | `nil` |  |
| worker.autoscaling.stabilizationWindowSeconds | int | `0` |  |
| worker.enabled | bool | `true` |  |
| worker.healthPort | int | `3334` |  |
| worker.nodeSelector | object | `{}` |  |
| worker.podAnnotations | object | `{}` |  |
| worker.podDisruptionBudget.enabled | bool | `false` |  |
| worker.podDisruptionBudget.minAvailable | int | `1` |  |
| worker.podLabels | object | `{}` |  |
| worker.replicaCount | int | `1` |  |
| worker.resources | object | `{}` |  |
| worker.role | string | `"code-review"` |  |
| worker.terminationGracePeriodSeconds | int | `660` |  |
| worker.tolerations | list | `[]` |  |
| worker.topologySpreadConstraints | list | `[]` |  |
| workerAnalytics.affinity | object | `{}` |  |
| workerAnalytics.enabled | bool | `false` |  |
| workerAnalytics.nodeSelector | object | `{}` |  |
| workerAnalytics.podAnnotations | object | `{}` |  |
| workerAnalytics.podDisruptionBudget.enabled | bool | `false` |  |
| workerAnalytics.podDisruptionBudget.minAvailable | int | `1` |  |
| workerAnalytics.podLabels | object | `{}` |  |
| workerAnalytics.replicaCount | int | `1` |  |
| workerAnalytics.resources | object | `{}` |  |
| workerAnalytics.role | string | `"analytics"` |  |
| workerAnalytics.tolerations | list | `[]` |  |
| workerAnalytics.topologySpreadConstraints | list | `[]` |  |
