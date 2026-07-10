#!/usr/bin/env bash
set -euo pipefail
if [ "${RUNNER_DEBUG:-0}" = "1" ]; then set -x; fi

namespace="${1:-default}"
attempts="${2:-10}"
delay="${3:-10}"
manifest="$(cd "$(dirname "$0")" && pwd)/services/deps.yaml"

for ((attempt = 1; attempt <= attempts; attempt++)); do
  if kubectl apply -f "$manifest"; then
    exec bash "$(dirname "$0")/wait-for-deps.sh" "$namespace"
  fi

  echo "kubectl apply failed (attempt ${attempt}/${attempts}); retrying in ${delay}s..." >&2
  sleep "$delay"
done

echo "Failed to apply CI dependencies after ${attempts} attempts." >&2
exit 1
