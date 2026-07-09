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

kubectl -n "$namespace" wait --for=condition=Ready cluster/postgres --timeout=600s
kubectl -n "$namespace" wait --for=jsonpath='{.status.applied}'=true database/kodus-db --timeout=300s
wait_for_ready_pods "cnpg.io/poolerName=postgres-pooler-rw" 300 || true
kubectl -n "$namespace" wait --for=jsonpath='{.status.phase}'=Running mongodbcommunity/mongodb --timeout=600s
wait_for_ready_pods "app=mongodb-svc" 600
kubectl -n "$namespace" wait --for=condition=ClusterAvailable rabbitmqcluster/rabbitmq --timeout=600s
wait_for_ready_pods "app.kubernetes.io/name=rabbitmq" 600

rabbitmq_pod="$(kubectl -n "$namespace" get pods -l app.kubernetes.io/name=rabbitmq -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "$namespace" exec "${rabbitmq_pod}" -- rabbitmqctl add_vhost kodus-ai || true
kubectl -n "$namespace" exec "${rabbitmq_pod}" -- rabbitmqctl set_permissions -p kodus-ai kodus ".*" ".*" ".*"

echo "All CI dependencies are ready."
