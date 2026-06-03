#!/bin/bash
set -e

TUTORIAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TUTORIAL_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/env.sh"
__env_load
source "${REPO_ROOT}/scripts/print-help.sh"

print_info "Applying Gateway API resources..."
kubectl apply -f "${TUTORIAL_DIR}/k8s/"

print_info "Waiting for Gateway to be programmed..."
kubectl wait gateway/kannika -n kannika-system \
  --for=condition=Programmed \
  --timeout=120s

ENVOY_SVC=$(kubectl get svc -n envoy-gateway-system -o name | grep envoy-kannika-system-kannika)
ENVOY_SVC=$(basename "$ENVOY_SVC")

print_info "Gateway API is ready."
echo ""
echo "  Console (HTTPS): https://localhost:8443"
echo "  Console (HTTP):  http://localhost:8080"
echo "  GraphQL API:     https://localhost:8443/gql"
echo "  REST API:        https://localhost:8443/rest"
echo ""
print_info "Start the port-forward:"
echo ""
echo "  kubectl port-forward -n envoy-gateway-system svc/${ENVOY_SVC} 8443:443 8080:80"
echo ""
