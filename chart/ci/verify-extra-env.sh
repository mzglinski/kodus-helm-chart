#!/usr/bin/env bash
set -euo pipefail
if [ "${RUNNER_DEBUG:-0}" = "1" ]; then set -x; fi

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(cd "${chart_dir}/.." && pwd)"

cd "${repo_root}"

render() {
  helm template kodus "${chart_dir}" -f "${chart_dir}/ci/lint.yaml" "$@"
}

# Print every value for env NAME inside the document whose metadata.name matches.
# kind is Deployment or Job. name_match is "exact" or "prefix".
# Literal values print as value:<text> (quotes removed). valueFrom prints
# valueFrom:<secretKeyRef|configMapKeyRef>:<name>:<key>.
env_records() {
  local kind="$1"
  local resource_name="$2"
  local name_match="$3"
  local env_name="$4"
  local manifest="$5"
  printf '%s\n' "${manifest}" | awk \
    -v kind="${kind}" \
    -v resource_name="${resource_name}" \
    -v name_match="${name_match}" \
    -v env_name="${env_name}" '
    function selected() {
      if (doc_kind != kind || doc_name == "") return 0
      if (name_match == "prefix") return index(doc_name, resource_name) == 1
      return doc_name == resource_name
    }
    function indent_of(line) {
      match(line, /^[[:space:]]*/)
      return RLENGTH
    }
    function finish_env() {
      if (!capturing) return
      if (mode == "value") print "value:" value
      else if (mode == "valueFrom") print "valueFrom:" refkind ":" refname ":" refkey
      else print "INVALID"
      capturing = 0
    }
    /^---$/ { finish_env(); in_env = 0; doc_kind = ""; doc_name = ""; next }
    /^kind: / { doc_kind = $2; next }
    /^  name: / && doc_name == "" { doc_name = $2; next }
    { if (!selected()) next }
    /^[[:space:]]+env:[[:space:]]*$/ && !in_env {
      in_env = 1
      env_indent = indent_of($0)
      next
    }
    in_env && /^[[:space:]]*[^[:space:]]/ && indent_of($0) <= env_indent {
      finish_env()
      in_env = 0
      next
    }
    in_env && $0 ~ "^[[:space:]]+- name: " env_name "$" {
      finish_env()
      capturing = 1
      mode = ""
      value = ""
      refkind = ""
      refname = ""
      refkey = ""
      next
    }
    in_env && /^[[:space:]]+- name: / { finish_env(); next }
    capturing && /^[[:space:]]+value: / {
      value = $0
      sub(/^[[:space:]]*value:[[:space:]]*/, "", value)
      if (value ~ /^".*"$/) {
        sub(/^"/, "", value)
        sub(/"$/, "", value)
      }
      mode = "value"
      next
    }
    capturing && /^[[:space:]]+valueFrom:[[:space:]]*$/ { mode = "valueFrom"; next }
    capturing && mode == "valueFrom" && /^[[:space:]]+(secretKeyRef|configMapKeyRef):[[:space:]]*$/ {
      refkind = $1
      sub(/:$/, "", refkind)
      next
    }
    capturing && mode == "valueFrom" && /^[[:space:]]+name: / { refname = $2; next }
    capturing && mode == "valueFrom" && /^[[:space:]]+key: / { refkey = $2; next }
    END { finish_env() }
  '
}

assert_values() {
  local kind="$1"
  local resource_name="$2"
  local name_match="$3"
  local env_name="$4"
  local expected="$5"
  local manifest="$6"
  local actual
  actual="$(env_records "${kind}" "${resource_name}" "${name_match}" "${env_name}" "${manifest}" | paste -sd ',' -)"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "${kind} ${resource_name} ${env_name}: expected '${expected}', got '${actual}'" >&2
    exit 1
  fi
}

assert_absent() {
  local kind="$1"
  local resource_name="$2"
  local name_match="$3"
  local env_name="$4"
  local manifest="$5"
  local actual
  actual="$(env_records "${kind}" "${resource_name}" "${name_match}" "${env_name}" "${manifest}")"
  if [[ -n "${actual}" ]]; then
    echo "${kind} ${resource_name} ${env_name}: expected no entries, got '${actual}'" >&2
    exit 1
  fi
}

expect_failure() {
  local label="$1"
  local values_file="$2"
  local err_file
  err_file="$(mktemp)"
  if helm template kodus "${chart_dir}" -f "${chart_dir}/ci/lint.yaml" -f "${values_file}" >/dev/null 2>"${err_file}"; then
    echo "${label}: expected helm template to fail" >&2
    cat "${err_file}" >&2
    exit 1
  fi
  if ! grep -Eq 'extraEnv|value or valueFrom|anyOf|Invalid type' "${err_file}"; then
    echo "${label}: failure did not mention extraEnv validation" >&2
    cat "${err_file}" >&2
    exit 1
  fi
  rm -f "${err_file}"
}

manifest="$(render -f "${chart_dir}/ci/extra-env.yaml")"

workloads=(
  "Deployment kodus-api exact"
  "Deployment kodus-worker exact"
  "Deployment kodus-worker-analytics exact"
  "Deployment kodus-webhooks exact"
  "Deployment kodus-web exact"
  "Deployment kodus-mcp-manager exact"
  "Deployment kodus-cron-api exact"
  "Deployment kodus-cron-worker exact"
  "Deployment kodus-cron-worker-analytics exact"
  "Job kodus-migrations- prefix"
  "Job kodus-seeds- prefix"
)

for spec in "${workloads[@]}"; do
  # shellcheck disable=SC2086
  set -- ${spec}
  assert_values "$1" "$2" "$3" ONLY_GLOBAL "value:from-global" "${manifest}"
  assert_values "$1" "$2" "$3" FROM_GLOBAL_SECRET "valueFrom:secretKeyRef:kodus-extra:global-token" "${manifest}"
done

assert_values Deployment kodus-api exact SHARED "value:from-api" "${manifest}"
assert_values Deployment kodus-api exact ONLY_API "value:from-api" "${manifest}"
assert_values Deployment kodus-api exact API_DEVELOPMENT_MODE "value:false,value:true" "${manifest}"
assert_values Deployment kodus-api exact BOOL_FALSE "value:false" "${manifest}"
assert_values Deployment kodus-api exact NUM_ZERO "value:0" "${manifest}"
assert_absent Deployment kodus-api exact ONLY_WORKER "${manifest}"

assert_values Deployment kodus-worker exact SHARED "value:from-global" "${manifest}"
assert_values Deployment kodus-worker exact ONLY_WORKER "value:from-worker" "${manifest}"
assert_values Deployment kodus-worker exact WORKER_SECRET "valueFrom:secretKeyRef:kodus-extra:worker-token" "${manifest}"
assert_absent Deployment kodus-worker exact ONLY_API "${manifest}"

assert_values Deployment kodus-worker-analytics exact ONLY_WORKER_ANALYTICS "value:from-worker-analytics" "${manifest}"
assert_absent Deployment kodus-worker-analytics exact ONLY_WORKER "${manifest}"

assert_values Deployment kodus-webhooks exact EMPTY_STRING "value:" "${manifest}"
assert_absent Deployment kodus-webhooks exact ONLY_API "${manifest}"

assert_values Deployment kodus-web exact ONLY_WEB "value:from-web" "${manifest}"
assert_absent Deployment kodus-web exact ONLY_API "${manifest}"

assert_values Deployment kodus-mcp-manager exact ONLY_MCP "value:from-mcp" "${manifest}"
assert_absent Deployment kodus-mcp-manager exact ONLY_API "${manifest}"

assert_values Deployment kodus-cron-api exact ONLY_CRON_API "value:from-cron-api" "${manifest}"
assert_values Deployment kodus-cron-api exact SHARED "value:from-global" "${manifest}"
assert_absent Deployment kodus-cron-api exact ONLY_API "${manifest}"

assert_values Deployment kodus-cron-worker exact ONLY_CRON_WORKER "value:from-cron-worker" "${manifest}"
assert_absent Deployment kodus-cron-worker exact ONLY_WORKER "${manifest}"

assert_values Deployment kodus-cron-worker-analytics exact ONLY_CRON_WORKER_ANALYTICS "value:from-cron-worker-analytics" "${manifest}"
assert_absent Deployment kodus-cron-worker-analytics exact ONLY_WORKER_ANALYTICS "${manifest}"

assert_values Job kodus-migrations- prefix ONLY_MIGRATIONS "value:from-migrations" "${manifest}"
assert_absent Job kodus-migrations- prefix ONLY_API "${manifest}"

assert_values Job kodus-seeds- prefix ONLY_SEEDS "value:from-seeds" "${manifest}"
assert_absent Job kodus-seeds- prefix ONLY_API "${manifest}"

tmp="$(mktemp -d)"
cat > "${tmp}/missing-value.yaml" <<'EOF'
api:
  extraEnv:
    - name: MISSING_VALUE
EOF
cat > "${tmp}/not-a-list.yaml" <<'EOF'
global:
  extraEnv:
    name: NOT_A_LIST
EOF
cat > "${tmp}/missing-name.yaml" <<'EOF'
web:
  extraEnv:
    - value: no-name
EOF
cat > "${tmp}/null-value.yaml" <<'EOF'
api:
  extraEnv:
    - name: NULL_VALUE
      value: null
EOF
expect_failure "missing value" "${tmp}/missing-value.yaml"
expect_failure "not a list" "${tmp}/not-a-list.yaml"
expect_failure "missing name" "${tmp}/missing-name.yaml"
expect_failure "null value" "${tmp}/null-value.yaml"
rm -rf "${tmp}"

echo "extra env wiring ok"
