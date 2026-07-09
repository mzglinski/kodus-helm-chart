# kodus-helm-chart

Community-maintained Helm chart for [Kodus AI](https://kodus.io) self-hosted deployments.

**Disclaimer:** This chart is not officially supported by Kodus Tech. See [DISCLAIMER.md](DISCLAIMER.md).

## Chart documentation

Configuration reference (auto-generated from `values.yaml`):

- [chart/README.md](chart/README.md)

Regenerate after values changes:

```bash
make docs
```

## Install

### From the published Helm repository

```bash
helm repo add kodus https://mzglinski.github.io/kodus-helm-chart
helm repo update
helm install kodus kodus/kodus -f my-values.yaml
```

### From a local checkout

```bash
helm install kodus ./chart -f my-values.yaml
```

See [chart/README.md](chart/README.md) for prerequisites (PostgreSQL, MongoDB, RabbitMQ) and configuration options.

## Versioning

- **Chart version** (`version` in `Chart.yaml`) is managed by [Release Please](https://github.com/googleapis/release-please) on merge to the default branch; releases are tagged `vX.Y.Z`.
- **Application version** (`appVersion` in `Chart.yaml`) tracks [kodustech/kodus-ai](https://github.com/kodustech/kodus-ai) **self-hosted** releases (`selfhosted-X.Y.Z` tags; container images are published as `X.Y.Z`). [Renovate](https://github.com/renovatebot/renovate) ignores cloud-only releases. `image.tag` defaults to `appVersion` when unset.

## CI fixtures

Chart-testing values and cluster fixtures:

- `chart/ci/lint.yaml` — explicit `helm template` / `helm lint` values (no cluster required; named outside the `ci/*-values.yaml` glob so chart-testing does not run a separate install with it)
- `chart/ci/kind-values.yaml` — `ct install` on kind (with `chart/ci/services/` operators)

## License

GPL-3.0 — see [LICENSE](LICENSE).
