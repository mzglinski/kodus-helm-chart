#!/usr/bin/env bash
set -euo pipefail
if [ "${RUNNER_DEBUG:-0}" = "1" ]; then set -x; fi

namespace="${1:-default}"

wait_for_ready_pods() {
  local selector=$1
  local timeout=$2
  local deadline=$((SECONDS + timeout))

  while (( SECONDS < deadline )); do
    if kubectl -n "$namespace" get pods -l "$selector" --no-headers 2>/dev/null | grep -q .; then
      kubectl -n "$namespace" wait --for=condition=ready pod -l "$selector" --timeout="$((deadline - SECONDS))s"
      return 0
    fi
    sleep 3
  done

  echo "Timed out waiting for ready pods (${selector})" >&2
  return 1
}

wait_for_ready_pods "cnpg.io/cluster=postgres" 600

postgres_pod="$(kubectl -n "$namespace" get pods -l cnpg.io/cluster=postgres,cnpg.io/instanceRole=primary -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "$namespace" exec "${postgres_pod}" -c postgres -- psql -U postgres -d kodus_db -c "CREATE EXTENSION IF NOT EXISTS vector;"

wait_for_ready_pods "cnpg.io/poolerName=postgres-pooler-rw" 300 || true
wait_for_ready_pods "app=mongodb-svc" 300
kubectl -n "$namespace" wait --for=condition=ClusterAvailable rabbitmqcluster/rabbitmq --timeout=600s
wait_for_ready_pods "app.kubernetes.io/name=rabbitmq" 600

rabbitmq_pod="$(kubectl -n "$namespace" get pods -l app.kubernetes.io/name=rabbitmq -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "$namespace" exec "${rabbitmq_pod}" -- rabbitmqctl add_vhost kodus-ai || true
kubectl -n "$namespace" exec "${rabbitmq_pod}" -- rabbitmqctl set_permissions -p kodus-ai kodus ".*" ".*" ".*"

echo "All CI dependencies are ready."
