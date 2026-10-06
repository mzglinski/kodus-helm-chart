# kodus

Helm chart for self-hosted Kodus AI (stateless components only)

## Prerequisites

External PostgreSQL (with pgvector), MongoDB 8.x, and RabbitMQ (with `rabbitmq_delayed_message_exchange` plugin) are required.

When connecting through **PgBouncer** (recommended for CNPG or other pooled Postgres), use **session** pooling — Kodus relies on session-scoped advisory locks (`pg_try_advisory_lock`). Transaction pooling breaks unlock and can block re-reviews. Configure PgBouncer to ignore startup parameters Kodus sends on connect: `statement_timeout` and `idle_in_transaction_session_timeout` (CNPG: `pgbouncer.parameters.ignore_startup_parameters`). See [kodus-deployment pooler.yaml](https://github.com/mzglinski/kodus-deployment/blob/main/terraform/modules/operators/postgresql/pooler.yaml) for a production reference.

## Resources

The chart does not ship CPU/memory requests or limits — set `<component>.resources` (and `jobs.*.resources` for hook Jobs) for your cluster and workload. Tools such as [KRR](https://github.com/robusta-dev/krr) can help derive starting values from live usage. Requests are required when using HPA resource metrics.

## Secrets

Set `secrets.existingSecret` to a pre-provisioned Secret for production. When empty, a **pre-install/pre-upgrade** hook generates installer-compatible secrets (see [kodus-installer `schema-vars.sh`](https://github.com/kodustech/kodus-installer/blob/main/scripts/schema-vars.sh)), preserves existing keys on upgrade via `lookup`, and keeps the Secret across releases (`helm.sh/resource-policy: keep`). With `helm template` or Argo CD dry-run, `lookup` returns empty and the hook manifest shows freshly generated values.

Database **URI mode** (`externalPostgresql.uri`, `externalMongodb.uri`, `externalRabbitmq.uri`) stores connection strings in the app Secret (`pg-uri`, `mongo-uri`, `rabbitmq-uri`) and wires pods via `secretKeyRef`. When `secrets.existingSecret` is set, add those keys to your Secret manually. RabbitMQ credentials can alternatively live in `externalRabbitmq.existingSecret` (`usernameKey` / `passwordKey`); the hook builds `rabbitmq-uri`.

`externalPostgresql.uri` is incompatible with `jobs.migrations` and analytics workers: the analytics warehouse has no URL env var and requires discrete `API_PG_DB_*` fields — use host/port/username/database instead.

MongoDB `authSource` is emitted as `API_MG_DB_PRODUCTION_CONFIG` (`?authSource=…`), matching `MongooseFactory` production URI assembly.

## Service ports

Container/service ports (`api.port`, `webhooks.port`) are the single source of truth for `API_PORT` / `API_WEBHOOKS_PORT` / `WEB_PORT_API` — do not duplicate them under `config.*`.

## Extra environment variables

`global.extraEnv` is appended to every container: api, worker, worker-analytics, webhooks, web, mcp-manager, cron runners, and the migration and seed Jobs. Each component has its own list (`api.extraEnv`, `worker.extraEnv`, `workerAnalytics.extraEnv`, `webhooks.extraEnv`, `web.extraEnv`, `mcpManager.extraEnv`, `cronRunner.api.extraEnv`, `cronRunner.worker.extraEnv`, `cronRunner.workerAnalytics.extraEnv`, `jobs.migrations.extraEnv`, `jobs.seeds.extraEnv`).

Entries are appended after the chart's own variables. A component entry with the same `name` replaces the global entry. An extra entry that repeats a chart-managed name is kept as a later entry; the container receives that later value.

Cron runners and hook Jobs use their own lists (`cronRunner.*.extraEnv`, `jobs.migrations.extraEnv`, `jobs.seeds.extraEnv`). Shared variables belong in `global.extraEnv`.

Each entry needs `name` and either `value` or `valueFrom` (`value` wins when both are set). `false`, `0`, and `""` are passed through.

```yaml
global:
  extraEnv:
    - name: HTTP_PROXY
      value: http://proxy.internal:3128
api:
  extraEnv:
    - name: API_CUSTOM_FLAG
      value: "true"
    - name: API_CUSTOM_TOKEN
      valueFrom:
        secretKeyRef:
          name: kodus-extra
          key: token
```

## Database migrations and seeds

Migrations and seeds run as **pre-install/pre-upgrade hook Jobs** (`jobs.migrations`, `jobs.seeds`) before Deployments roll out; application pods never migrate on boot.

## Service accounts

`serviceAccount.create` defaults to `false` — workloads and hook jobs use the namespace `default` account. Set `serviceAccount.name` and/or `serviceAccount.hooks.name` to use pre-existing accounts. To create chart-managed accounts, set `serviceAccount.create: true`; add `serviceAccount.hooks.create: true` for a separate hook SA (created as a pre-upgrade hook before migrations, `{release}-hooks` by default).

## Scheduled jobs (crons)

Kodus uses NestJS `@Cron` inside the **api**, **worker**, and **webhooks** processes. By default crons run in those Deployments (`cronRunner.enabled: false`).

Set `cronRunner.enabled: true` when `api` / `worker` / `webhooks` run with more than one replica (fixed `replicaCount` or HPA `minReplicas` > 1): the chart can add single-replica **cron-api**, **cron-worker**, and **cron-worker-analytics** pods with real schedules. Each main Deployment only gets leap-day expressions (`0 0 29 2 *`) when its matching `cronRunner.<component>.enabled` is true — e.g. `cronRunner.worker.enabled: false` leaves worker crons on the HA worker pods. **webhooks** has no dedicated cron runner and always keeps real schedules. Many jobs also use Postgres advisory locks, but coverage is not complete.

## Langfuse (optional)

Opt-in LLM/review tracing via [Langfuse](https://langfuse.com). Set `langfuse.enabled: true`, `langfuse.publicKey`, and add `langfuse-secret-key` (or your `secrets.keys.langfuseSecretKey`) to the app Secret. Override `langfuse.baseUrl` for self-hosted Langfuse. Env is wired to api, worker, webhooks, worker-analytics, and cron runners — not web.

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
| api.extraEnv | list | `[]` | Extra environment variables for the api container. Replaces `global.extraEnv` entries with the same name. |
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
| config.agentReviewEnabled | bool | `true` | Force the agent-based code review engine on for every organization (API_AGENT_REVIEW_ENABLED). |
| config.analytics.classifierCron | string | `"*/15 * * * *"` | Cron for the LLM PR-type classifier on the analytics worker (ANALYTICS_CLASSIFIER_CRON). |
| config.analytics.classifierDisabled | bool | `false` | Disable the analytics PR-type classifier (ANALYTICS_CLASSIFIER_DISABLED). |
| config.analytics.ingestionCron | string | `"*/30 * * * *"` | Cron for analytics ingestion (ANALYTICS_INGESTION_CRON). Default is every 30 minutes. |
| config.analytics.ingestionDisabled | bool | `false` | Disable the analytics ingestion cron regardless of worker role (ANALYTICS_INGESTION_DISABLED). |
| config.analytics.ingestionRunOnBoot | bool | `true` | Run one analytics ingestion pass on worker boot (ANALYTICS_INGESTION_RUN_ON_BOOT). Set false to wait for the first scheduled tick. |
| config.analytics.pgPoolMax | int | `5` | Upper bound on the analytics Postgres pool (ANALYTICS_PG_POOL_MAX). |
| config.analytics.pgSchema | string | `"analytics"` | Schema name in the analytics Postgres database (ANALYTICS_PG_DB_SCHEMA). |
| config.cron.checkIfPrShouldBeApproved | string | `"*/2 * * * *"` | Every 2 minutes (API_CRON_CHECK_IF_PR_SHOULD_BE_APPROVED). |
| config.cron.classifyOrphanedSessions | string | `"0 */15 * * * *"` | Reclassifies orphaned review sessions every 15 minutes (API_CRON_CLASSIFY_ORPHANED_SESSIONS). Cloud-only. |
| config.cron.kodyLearning | string | `"0 0 * * 6"` | Saturday at 00:00 UTC (API_CRON_KODY_LEARNING). |
| config.cron.kodyRulesDetectorSweepEnabled | bool | `true` |  |
| config.cron.orgReport | string | `"0 9 1 * *"` | 1st of each month at 09:00 UTC. Organization review report email (API_CRON_ORG_REPORT). |
| config.cron.repoReport | string | `"0 9 1,16 * *"` | 1st and 16th at 09:00 UTC. Per-repository review digest email (API_CRON_REPO_REPORT). |
| config.cron.spendLimitAlert | string | `"0 * * * *"` | Every hour (API_CRON_SPEND_LIMIT_ALERT). |
| config.cron.ssoTestSessionCleanup | string | `"0 1 * * *"` | Daily cleanup of expired SSO test sessions, 1 AM UTC (API_CRON_SSO_TEST_SESSION_CLEANUP). |
| config.cron.staleReviewWatchdog | string | `"*/30 * * * *"` | Reaps code review executions stuck IN_PROGRESS and finalizes their orphaned platform check runs (API_CRON_STALE_REVIEW_WATCHDOG). |
| config.cron.syncCodeReviewReactions | string | `"0 0 * * *"` | Daily at 00:00 UTC (API_CRON_SYNC_CODE_REVIEW_REACTIONS). |
| config.cron.workflowStaleJobReaper | string | `"0 */10 * * * *"` | Cadence of the reaper that fails workflow jobs left PROCESSING after a worker is killed (WORKFLOW_STALE_JOB_REAPER_CRON). WORKFLOW_STALE_JOB_TIMEOUT_MINUTES still decides which jobs are eligible. |
| config.developmentMode | bool | `false` | Bypass permission validation (API_DEVELOPMENT_MODE). Cloud development only. |
| config.docs.basicUser | string | `""` | Basic auth user for API docs (API_DOCS_BASIC_USER). Leave empty to leave the docs open. |
| config.docs.enabled | bool | `false` |  |
| config.docs.path | string | `"/docs"` |  |
| config.docs.specPath | string | `"/openapi.json"` |  |
| config.email.provider | string | `"resend"` | Notifications email provider (API_NOTIFICATION_EMAIL_PROVIDER): resend or smtp. |
| config.email.smtp.from | string | `"noreply@notifications.kodus.io"` | SMTP notifications sender address (API_SMTP_FROM). |
| config.email.smtp.host | string | `""` | SMTP host (API_SMTP_HOST). |
| config.email.smtp.port | int | `587` | SMTP port (API_SMTP_PORT). |
| config.email.smtp.secure | string | `""` | SMTP secure mode (API_SMTP_SECURE). |
| config.email.smtp.user | string | `""` | SMTP user (API_SMTP_USER). |
| config.email.userInviteBaseUrl | string | `""` |  |
| config.github.appId | string | `""` |  |
| config.github.clientId | string | `""` |  |
| config.github.installUrl | string | `""` |  |
| config.github.webOAuthClientId | string | `""` |  |
| config.globalApiContainerName | string | `"kodus_api"` |  |
| config.jwtExpiresIn | string | `"365d"` |  |
| config.jwtRefreshExpiresIn | string | `"7d"` | Refresh token lifetime (API_JWT_REFRESH_EXPIRES_IN). Self-hosted default is 7d. |
| config.rabbitmqWait | bool | `true` | Wait for RabbitMQ to become reachable before the process finishes booting (API_RABBITMQ_WAIT). |
| config.rateInterval | int | `1000` | Rate limit interval in milliseconds (API_RATE_INTERVAL). |
| config.rateMaxRequest | int | `100` |  |
| config.sandbox.cloneTimeoutMs | string | `""` | Local sandbox git clone budget in milliseconds (API_SANDBOX_CLONE_TIMEOUT_MS). Empty uses the app default of 120000. Raise it when a shallow fetch of a large monorepo exceeds that budget and the review continues with no sandbox. |
| config.sandbox.provider | string | `"local"` | Sandbox provider (SANDBOX_PROVIDER): auto, e2b, local, or none. |
| config.web.nodeEnv | string | `"self-hosted"` |  |
| config.web.ruleFilesDocs | string | `"https://docs.kodus.io/how_to_use/en/code_review/configs/rules_file_detection"` | Documentation URL for rule-file detection, shown when configuring code review rules (WEB_RULE_FILES_DOCS). |
| config.web.supportDiscordInviteUrl | string | `"https://discord.gg/QFzwwmNmdN"` |  |
| config.web.supportDocsUrl | string | `"https://docs.kodus.io"` |  |
| config.web.supportTalkToFounderUrl | string | `"https://cal.com/gabrielmalinosqui/30min"` |  |
| config.web.tokenDocs.azureRepos | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/azure_devops_pat"` |  |
| config.web.tokenDocs.bitbucket | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/bitbucket_pat"` |  |
| config.web.tokenDocs.forgejo | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/forgejo_pat"` |  |
| config.web.tokenDocs.github | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/github_pat"` |  |
| config.web.tokenDocs.gitlab | string | `"https://docs.kodus.io/how_to_use/en/code_review/general_config/gitlab_pat"` |  |
| config.workerDrainTimeoutMs | int | `600000` | How long a worker keeps in-flight jobs during shutdown, in milliseconds, before it exits (API_WORKER_DRAIN_TIMEOUT_MS). |
| config.workflow.codeReviewPrefetch | int | `20` |  |
| config.workflow.codeReviewProcessTimeoutMs | int | `7200000` |  |
| config.workflow.outboxMaxAttempts | int | `10` | Retries before a workflow message is marked FAILED (WORKFLOW_OUTBOX_MAX_ATTEMPTS). |
| config.workflow.publisherPrefetch | int | `5` |  |
| config.workflow.staleJobTimeoutMinutes | int | `180` | Minutes a workflow job may stay PROCESSING before the reaper marks it FAILED (WORKFLOW_STALE_JOB_TIMEOUT_MINUTES). Must exceed the longest legitimate run; 180 leaves margin past the 150 minute claim timeout. |
| config.workflow.webhookPrefetch | int | `20` |  |
| config.workflow.webhookProcessTimeoutMs | int | `600000` |  |
| config.workflow.workerPrefetch | int | `20` |  |
| cronRunner.api.enabled | bool | `true` |  |
| cronRunner.api.extraEnv | list | `[]` | Extra environment variables for the cron-api container only. Replaces `global.extraEnv` entries with the same name. |
| cronRunner.api.replicaCount | int | `1` |  |
| cronRunner.api.resources | object | `{}` |  |
| cronRunner.disabledSchedule | string | `"0 0 29 2 *"` |  |
| cronRunner.disabledScheduleWithSeconds | string | `"0 0 0 29 2 *"` |  |
| cronRunner.enabled | bool | `false` |  |
| cronRunner.worker.enabled | bool | `true` |  |
| cronRunner.worker.extraEnv | list | `[]` | Extra environment variables for the cron-worker container only. Replaces `global.extraEnv` entries with the same name. |
| cronRunner.worker.replicaCount | int | `1` |  |
| cronRunner.worker.resources | object | `{}` |  |
| cronRunner.worker.role | string | `"code-review"` | Workload this worker handles (WORKER_ROLE). code-review owns the review queues. |
| cronRunner.workerAnalytics.enabled | bool | `false` |  |
| cronRunner.workerAnalytics.extraEnv | list | `[]` | Extra environment variables for the cron-worker-analytics container only. Replaces `global.extraEnv` entries with the same name. |
| cronRunner.workerAnalytics.replicaCount | int | `1` |  |
| cronRunner.workerAnalytics.resources | object | `{}` |  |
| cronRunner.workerAnalytics.role | string | `"analytics"` | Workload this worker handles (WORKER_ROLE). analytics is the Cockpit ingestion worker. |
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
| global.betaFeatures | bool | `false` | Opt in to beta-stage features (BETA_FEATURES). Leave false for generally-available features only. |
| global.databaseDisableSsl | bool | `true` | Disable SSL on Postgres connections, including the analytics warehouse (API_DATABASE_DISABLE_SSL). Leave true for in-cluster Postgres without TLS. Set false when the server requires SSL. |
| global.databaseEnv | string | `"production"` | Database environment selector (API_DATABASE_ENV). Affects SSL defaults. |
| global.extraEnv | list | `[]` | Extra environment variables for every container. Each entry is a Kubernetes EnvVar (`name` plus `value`, or `name` plus `valueFrom`). Appended after chart-managed variables; a component `extraEnv` entry with the same name replaces these. |
| global.extraVolumeMounts | list | `[]` |  |
| global.extraVolumes | list | `[]` |  |
| global.logLevel | string | `"error"` | Log verbosity (API_LOG_LEVEL). Self-hosted default is error. |
| global.logPretty | bool | `false` | Pretty-print logs when true; JSON when false (API_LOG_PRETTY). |
| global.mcpServerEnabled | bool | `false` | Enable MCP integration (API_MCP_SERVER_ENABLED). When false, MCP code paths are skipped. |
| global.nodeEnv | string | `"production"` | Runtime mode (API_NODE_ENV). Self-hosted installs use production. development emits the SSO handoff cookie without Domain or Secure, so a web app on another host cannot read it. |
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
| global.telemetryDisabled | bool | `true` | Opt out of the daily anonymous heartbeat to telemetry.kodus.io (KODUS_TELEMETRY_DISABLED). The payload is aggregated counters and runtime metadata, not source code or identifiers. |
| global.telemetryEndpoint | string | `""` | Heartbeat receiver override (KODUS_TELEMETRY_ENDPOINT). Leave empty to use https://telemetry.kodus.io/v1/heartbeat. |
| global.terminationGracePeriodSeconds | int | `30` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"ghcr.io/kodustech"` |  |
| image.tag | string | .Chart.AppVersion | Container image tag for all Kodus components. |
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
| jobs.migrations.extraEnv | list | `[]` | Extra environment variables for the migrations Job only. Replaces `global.extraEnv` entries with the same name. |
| jobs.migrations.resources | object | `{}` |  |
| jobs.seeds.activeDeadlineSeconds | int | `600` |  |
| jobs.seeds.backoffLimit | int | `3` |  |
| jobs.seeds.enabled | bool | `true` |  |
| jobs.seeds.extraEnv | list | `[]` | Extra environment variables for the seeds Job only. Replaces `global.extraEnv` entries with the same name. |
| jobs.seeds.resources | object | `{}` |  |
| langfuse.baseUrl | string | `"https://cloud.langfuse.com"` | Langfuse API base URL (cloud or self-hosted Langfuse). |
| langfuse.enabled | bool | `false` | Set LANGFUSE_TRACING=true when enabled (app also requires public + secret keys). |
| langfuse.environment | string | `""` | Trace environment label. When empty, the app falls back to API_NODE_ENV / development. |
| langfuse.publicKey | string | `""` | Langfuse project public key (pk-…). Not a Secret; pair with secrets.keys.langfuseSecretKey. |
| llm.cerebras.baseUrl | string | `"https://api.cerebras.ai/v1"` |  |
| llm.google.provider | string | `"gemini"` | Google AI provider (API_GOOGLE_AI_PROVIDER): gemini (AI Studio) or vertex (Vertex AI). |
| llm.google.vertexLocation | string | `"us-central1"` |  |
| llm.groq.baseUrl | string | `"https://api.groq.com/openai/v1"` |  |
| llm.openaiForceBaseUrl | string | `""` | OpenAI-compatible endpoint override, such as a local model proxy (API_OPENAI_FORCE_BASE_URL). |
| llm.providerModel | string | `"auto"` | Model id for env-mode LLM (API_LLM_PROVIDER_MODEL). "auto" lets the router pick per task. |
| llm.temperatureOverride | string | `""` | Temperature for every LLM call in env-mode (API_LLM_TEMPERATURE_OVERRIDE). Set this when the model only accepts a fixed temperature, such as 1 for some reasoning models. |
| llm.trustJsonSchemaBaseUrls | string | `""` | Comma-separated base URL substrings trusted for native json_schema output on OpenAI-compatible BYOK providers (API_TRUST_JSON_SCHEMA_BASE_URLS). Leave empty unless the proxy accepts json_schema. |
| mcpManager.affinity | object | `{}` |  |
| mcpManager.composioBaseUrl | string | `"https://backend.composio.dev/api/v3"` |  |
| mcpManager.corsOrigins | string | `"*"` | Comma-separated allowed origins for the MCP Manager HTTP server (API_MCP_MANAGER_CORS_ORIGINS). |
| mcpManager.databaseEnv | string | `"production"` |  |
| mcpManager.enabled | bool | `true` |  |
| mcpManager.extraEnv | list | `[]` | Extra environment variables for the MCP manager. Replaces `global.extraEnv` entries with the same name. |
| mcpManager.logLevel | string | `"info"` | Log verbosity for the MCP Manager process (API_MCP_MANAGER_LOG_LEVEL). |
| mcpManager.mcpProviders | string | `"kodusmcp,composio,custom"` | Comma-separated MCP providers to enable (API_MCP_MANAGER_MCP_PROVIDERS). |
| mcpManager.nodeEnv | string | `"production"` |  |
| mcpManager.nodeSelector | object | `{}` |  |
| mcpManager.pgSchema | string | `"mcp-manager"` | Postgres schema used by MCP Manager in the main database (API_MCP_MANAGER_PG_DB_SCHEMA). |
| mcpManager.podAnnotations | object | `{}` |  |
| mcpManager.podLabels | object | `{}` |  |
| mcpManager.port | int | `3101` |  |
| mcpManager.redirectUri | string | `""` | OAuth redirect URI MCP Manager uses when connecting providers from the web UI (API_MCP_MANAGER_REDIRECT_URI). Empty derives it from the public web URL. |
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
| secrets.keys.e2bKey | string | `"e2b-key"` | Secret key for API_E2B_KEY. Required when the sandbox provider is e2b. |
| secrets.keys.exaKey | string | `"exa-key"` | Secret key for API_EXA_KEY. When set, review agents can search external documentation. Without it they use repository context only. |
| secrets.keys.geminiApiKey | string | `"gemini-api-key"` |  |
| secrets.keys.githubAppClientSecret | string | `"github-app-client-secret"` |  |
| secrets.keys.githubAppPrivateKey | string | `"github-app-private-key"` |  |
| secrets.keys.googleAiApiKey | string | `"google-ai-api-key"` |  |
| secrets.keys.groqApiKey | string | `"groq-api-key"` |  |
| secrets.keys.langfuseSecretKey | string | `"langfuse-secret-key"` |  |
| secrets.keys.mcpManagerComposioApiKey | string | `"mcp-manager-composio-api-key"` |  |
| secrets.keys.moonshotApiKey | string | `"moonshot-api-key"` | Secret key for API_MOONSHOT_API_KEY (Kimi). Cloud-only; self-hosted does not use the Moonshot demo path. |
| secrets.keys.morphllmApiKey | string | `"morphllm-api-key"` | Secret key for API_MORPHLLM_API_KEY. When set, suggested edits are applied with MorphLLM instead of the main model. |
| secrets.keys.novitaAiApiKey | string | `"novita-ai-api-key"` |  |
| secrets.keys.openRouterApiKey | string | `"open-router-api-key"` | Secret key for API_OPEN_ROUTER_API_KEY. |
| secrets.keys.openaiApiKey | string | `"openai-api-key"` | Secret key for API_OPEN_AI_API_KEY. Required when the model is an OpenAI model. |
| secrets.keys.resendApiKey | string | `"resend-api-key"` | Secret key for RESEND_API_KEY when email.provider is resend. |
| secrets.keys.smtpPass | string | `"smtp-pass"` | Secret key for API_SMTP_PASS. |
| secrets.keys.vertexAiApiKey | string | `"vertex-ai-api-key"` | Secret key for API_VERTEX_AI_API_KEY, a base64-encoded Vertex service account JSON. Leave unset to use Application Default Credentials. |
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
| web.extraEnv | list | `[]` | Extra environment variables for the web container. Replaces `global.extraEnv` entries with the same name. |
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
| webhooks.extraEnv | list | `[]` | Extra environment variables for the webhooks container. Replaces `global.extraEnv` entries with the same name. |
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
| worker.extraEnv | list | `[]` | Extra environment variables for the worker container. Replaces `global.extraEnv` entries with the same name. |
| worker.healthPort | int | `3334` |  |
| worker.nodeSelector | object | `{}` |  |
| worker.podAnnotations | object | `{}` |  |
| worker.podDisruptionBudget.enabled | bool | `false` |  |
| worker.podDisruptionBudget.minAvailable | int | `1` |  |
| worker.podLabels | object | `{}` |  |
| worker.replicaCount | int | `1` |  |
| worker.resources | object | `{}` |  |
| worker.role | string | `"code-review"` | Workload this worker handles (WORKER_ROLE). code-review owns the review queues; the image refuses to boot without a role. |
| worker.terminationGracePeriodSeconds | int | `660` |  |
| worker.tolerations | list | `[]` |  |
| worker.topologySpreadConstraints | list | `[]` |  |
| workerAnalytics.affinity | object | `{}` |  |
| workerAnalytics.enabled | bool | `false` |  |
| workerAnalytics.extraEnv | list | `[]` | Extra environment variables for the analytics worker. Replaces `global.extraEnv` entries with the same name. |
| workerAnalytics.nodeSelector | object | `{}` |  |
| workerAnalytics.podAnnotations | object | `{}` |  |
| workerAnalytics.podDisruptionBudget.enabled | bool | `false` |  |
| workerAnalytics.podDisruptionBudget.minAvailable | int | `1` |  |
| workerAnalytics.podLabels | object | `{}` |  |
| workerAnalytics.replicaCount | int | `1` |  |
| workerAnalytics.resources | object | `{}` |  |
| workerAnalytics.role | string | `"analytics"` | Workload this worker handles (WORKER_ROLE). analytics is the Cockpit ingestion worker. |
| workerAnalytics.tolerations | list | `[]` |  |
| workerAnalytics.topologySpreadConstraints | list | `[]` |  |
