#!/usr/bin/env bash
set -euo pipefail
if [ "${RUNNER_DEBUG:-0}" = "1" ]; then set -x; fi

namespace="${1:-default}"

kubectl -n "$namespace" wait --for=condition=ready pod -l cnpg.io/cluster=postgres --timeout=600s
kubectl -n "$namespace" wait --for=condition=ready pod -l app.kubernetes.io/name=postgres-pooler --timeout=300s || \
  kubectl -n "$namespace" wait --for=condition=ready pod -l cnpg.io/poolerName=postgres-pooler-rw --timeout=300s || true
kubectl -n "$namespace" wait --for=jsonpath='{.status.phase}'=Running mongodbcommunity/mongodb --timeout=600s
kubectl -n "$namespace" wait --for=condition=ClusterAvailable rabbitmqcluster/rabbitmq --timeout=600s

rabbitmq_pod="$(kubectl -n "$namespace" get pods -l app.kubernetes.io/name=rabbitmq -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "$namespace" wait --for=condition=ready "pod/${rabbitmq_pod}" --timeout=300s
kubectl -n "$namespace" exec "${rabbitmq_pod}" -- rabbitmqctl add_vhost kodus-ai || true
kubectl -n "$namespace" exec "${rabbitmq_pod}" -- rabbitmqctl set_permissions -p kodus-ai kodus ".*" ".*" ".*"

echo "All CI dependencies are ready."
