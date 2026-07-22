# Changelog

## [0.2.1](https://github.com/mzglinski/kodus-helm-chart/compare/v0.2.0...v0.2.1) (2026-07-22)


### Bug Fixes

* **deps:** update dependency kodustech/kodus-ai to v2.1.27 ([#45](https://github.com/mzglinski/kodus-helm-chart/issues/45)) ([a041542](https://github.com/mzglinski/kodus-helm-chart/commit/a041542d1fcb0bf90c3a4862ac79f9a9d3f1e157))

## [0.2.0](https://github.com/mzglinski/kodus-helm-chart/compare/v0.1.4...v0.2.0) (2026-07-21)


### Features

* add opt-in Langfuse LLM tracing configuration ([#43](https://github.com/mzglinski/kodus-helm-chart/issues/43)) ([22eb805](https://github.com/mzglinski/kodus-helm-chart/commit/22eb8053ddc5f70164aec481c6700e758d544392))

## [0.1.4](https://github.com/mzglinski/kodus-helm-chart/compare/v0.1.3...v0.1.4) (2026-07-21)


### Bug Fixes

* **deps:** update dependency kodustech/kodus-ai to v2.1.26 ([#41](https://github.com/mzglinski/kodus-helm-chart/issues/41)) ([4858940](https://github.com/mzglinski/kodus-helm-chart/commit/48589400c5ee49d08ff782c63383161194d4a213))

## [0.1.3](https://github.com/mzglinski/kodus-helm-chart/compare/v0.1.2...v0.1.3) (2026-07-16)


### Miscellaneous Chores

* force release ([1f05926](https://github.com/mzglinski/kodus-helm-chart/commit/1f059260ba6e6d02987f3be2c7b5551f38b0faa2))

## [0.1.2](https://github.com/mzglinski/kodus-helm-chart/compare/v0.1.1...v0.1.2) (2026-07-14)


### Bug Fixes

* only disable crons when dedicated cron runner is enabled ([#36](https://github.com/mzglinski/kodus-helm-chart/issues/36)) ([3659365](https://github.com/mzglinski/kodus-helm-chart/commit/36593658421bd51314266b35d54b31daac8962cd))

## [0.1.1](https://github.com/mzglinski/kodus-helm-chart/compare/v0.1.0...v0.1.1) (2026-07-10)


### Bug Fixes

* cap RabbitMQ below 4.3 and enable Renovate for chart/ci ([#27](https://github.com/mzglinski/kodus-helm-chart/issues/27)) ([4dd48e9](https://github.com/mzglinski/kodus-helm-chart/commit/4dd48e9525dd7eae5ab4a91270fbce70af2103bd))
* **chart:** default image.tag to Chart.appVersion for Renovate ([#12](https://github.com/mzglinski/kodus-helm-chart/issues/12)) ([b4032d3](https://github.com/mzglinski/kodus-helm-chart/commit/b4032d3bf98292201d2574768531cce7047f1431))
* **ci:** always run chart tests and fix operator 2.22 fixtures ([#18](https://github.com/mzglinski/kodus-helm-chart/issues/18)) ([7bd75e0](https://github.com/mzglinski/kodus-helm-chart/commit/7bd75e0f2d7eb84c6d92c46dc869a3449b0d395f))
* **ci:** wait for RabbitMQ webhook before applying deps ([#25](https://github.com/mzglinski/kodus-helm-chart/issues/25)) ([edd3c21](https://github.com/mzglinski/kodus-helm-chart/commit/edd3c21323adbe5ee6ae6b5321dfc4b482049788))
* enable MCP Manager in chart hooks, env, and CI ([#30](https://github.com/mzglinski/kodus-helm-chart/issues/30)) ([c154725](https://github.com/mzglinski/kodus-helm-chart/commit/c154725a3f0af1a527b06dd5654aa641dc77c7aa))
* **renovate:** track kodus-ai self-hosted releases only ([#15](https://github.com/mzglinski/kodus-helm-chart/issues/15)) ([15e16ce](https://github.com/mzglinski/kodus-helm-chart/commit/15e16ce2bcd14b15f03576097d104020a231ba73))

## [0.1.0](https://github.com/mzglinski/kodus-helm-chart/compare/v0.0.1...v0.1.0) (2026-07-09)


### Features

* initial commit ([0e306c0](https://github.com/mzglinski/kodus-helm-chart/commit/0e306c002ff39246ed5df4246d45729a8e9d7784))


### Bug Fixes

* release-please config ([1efd46f](https://github.com/mzglinski/kodus-helm-chart/commit/1efd46f3e08b84f44d9fbec18e1627a48a77a822))
