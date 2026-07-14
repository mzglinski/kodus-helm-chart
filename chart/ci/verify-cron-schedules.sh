#!/usr/bin/env bash
set -euo pipefail
if [ "${RUNNER_DEBUG:-0}" = "1" ]; then set -x; fi

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(cd "${chart_dir}/.." && pwd)"

render() {
  helm template kodus "${chart_dir}" -f "${chart_dir}/ci/lint.yaml" "$@"
}

cron_value_for_deployment() {
  local deployment="$1"
  local manifest="$2"
  printf '%s\n' "${manifest}" | awk -v dep="${deployment}" '
    /^kind: Deployment$/ { current_dep="" }
    /^  name:/ && current_dep == "" { current_dep=$2 }
    current_dep == dep && /- name: API_CRON_SYNC_CODE_REVIEW_REACTIONS/ {
      getline
      sub(/^[[:space:]]*value:[[:space:]]*"/, "")
      sub(/"[[:space:]]*$/, "")
      value=$0
    }
    /^---$/ { current_dep="" }
    END { if (value != "") print value }
  '
}

has_deployment() {
  local deployment="$1"
  local manifest="$2"
  printf '%s\n' "${manifest}" | awk -v dep="${deployment}" '
    /^kind: Deployment$/ { current_dep="" }
    /^  name:/ && current_dep == "" { current_dep=$2 }
    current_dep == dep { found=1 }
    END { exit !found }
  '
}

assert_worker_cron() {
  local manifest="$1"
  local expected="$2"
  local actual
  actual="$(cron_value_for_deployment "kodus-worker" "${manifest}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "kodus-worker API_CRON_SYNC_CODE_REVIEW_REACTIONS: expected '${expected}', got '${actual}'" >&2
    exit 1
  fi
}

assert_api_cron() {
  local manifest="$1"
  local expected="$2"
  local actual
  actual="$(cron_value_for_deployment "kodus-api" "${manifest}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "kodus-api API_CRON_SYNC_CODE_REVIEW_REACTIONS: expected '${expected}', got '${actual}'" >&2
    exit 1
  fi
}

assert_webhooks_cron() {
  local manifest="$1"
  local expected="$2"
  local actual
  actual="$(cron_value_for_deployment "kodus-webhooks" "${manifest}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "kodus-webhooks API_CRON_SYNC_CODE_REVIEW_REACTIONS: expected '${expected}', got '${actual}'" >&2
    exit 1
  fi
}

cd "${repo_root}"

partial_manifest="$(render -f "${chart_dir}/ci/cron-runner-partial.yaml")"
assert_worker_cron "${partial_manifest}" "0 0 * * *"
assert_api_cron "${partial_manifest}" "0 0 29 2 *"
assert_webhooks_cron "${partial_manifest}" "0 0 * * *"
if has_deployment "kodus-cron-worker" "${partial_manifest}"; then
  echo "expected no kodus-cron-worker Deployment for cron-runner-partial.yaml" >&2
  exit 1
fi

default_manifest="$(render)"
assert_worker_cron "${default_manifest}" "0 0 * * *"

full_manifest="$(render -f - <<'EOF'
cronRunner:
  enabled: true
  worker:
    enabled: true
EOF
)"
assert_worker_cron "${full_manifest}" "0 0 29 2 *"
if ! has_deployment "kodus-cron-worker" "${full_manifest}"; then
  echo "expected kodus-cron-worker Deployment when cronRunner.worker.enabled=true" >&2
  exit 1
fi

echo "cron schedule verification passed"
