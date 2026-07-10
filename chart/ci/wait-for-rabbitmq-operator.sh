#!/usr/bin/env bash
set -euo pipefail
if [ "${RUNNER_DEBUG:-0}" = "1" ]; then set -x; fi

namespace="${1:-rabbitmq-system}"
operator_timeout="${2:-300}"

wait_for_endpoints() {
  local service=$1
  local timeout=$2
  local deadline=$((SECONDS + timeout))

  while (( SECONDS < deadline )); do
    if kubectl -n "$namespace" get endpoints "$service" -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null | grep -q .; then
      return 0
    fi
    sleep 3
  done

  echo "Timed out waiting for endpoints on ${namespace}/${service}" >&2
  return 1
}

wait_for_webhook() {
  local timeout=$1
  local deadline=$((SECONDS + timeout))

  while (( SECONDS < deadline )); do
    if kubectl apply --dry-run=server -f - <<'EOF' >/dev/null 2>&1
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: ci-webhook-probe
  namespace: default
spec:
  replicas: 1
EOF
    then
      return 0
    fi
    sleep 3
  done

  echo "Timed out waiting for RabbitMQ admission webhook" >&2
  return 1
}

kubectl -n "$namespace" wait --for=condition=ready pod -l app.kubernetes.io/name=rabbitmq-cluster-operator --timeout="${operator_timeout}s"
kubectl -n "$namespace" wait --for=condition=Ready certificate/cluster-operator-serving-cert --timeout="${operator_timeout}s"
wait_for_endpoints cluster-operator-webhook-service "$operator_timeout"
wait_for_webhook "$operator_timeout"

echo "RabbitMQ cluster operator webhook is ready."
