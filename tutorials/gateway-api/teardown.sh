#!/bin/bash
set -e

TUTORIAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TUTORIAL_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/env.sh"
__env_load
source "${REPO_ROOT}/scripts/print-help.sh"

print_info "Uninstalling Envoy Gateway..."
helm uninstall eg -n envoy-gateway-system 2>/dev/null || true
kubectl delete namespace envoy-gateway-system 2>/dev/null || true
