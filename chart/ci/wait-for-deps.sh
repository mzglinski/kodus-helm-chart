#!/usr/bin/env bash
set -euo pipefail
if [ "${RUNNER_DEBUG:-0}" = "1" ]; then set -x; fi

namespace="${1:-default}"

kubectl -n "$namespace" wait --for=condition=ready pod -l cnpg.io/cluster=postgres --timeout=600s
kubectl -n "$namespace" wait --for=condition=ready pod -l app.kubernetes.io/name=postgres-pooler --timeout=300s || \
  kubectl -n "$namespace" wait --for=condition=ready pod -l cnpg.io/poolerName=postgres-pooler-rw --timeout=300s || true
kubectl -n "$namespace" wait --for=jsonpath='{.status.phase}'=Running mongodbcommunity/mongodb --timeout=600s
kubectl -n "$namespace" wait --for=condition=ClusterAvailable rabbitmqcluster/rabbitmq --timeout=600s

echo "All CI dependencies are ready."
