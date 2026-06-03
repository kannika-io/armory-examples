#!/bin/bash
set -e

TUTORIAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TUTORIAL_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/env.sh"
__env_load
source "${REPO_ROOT}/scripts/print-help.sh"

print_info "Creating self-signed TLS certificate..."
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /tmp/kannika-tls.key \
  -out /tmp/kannika-tls.crt \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost" \
  2>/dev/null

kubectl create secret tls kannika-tls \
  -n kannika-system \
  --cert=/tmp/kannika-tls.crt \
  --key=/tmp/kannika-tls.key

rm -f /tmp/kannika-tls.key /tmp/kannika-tls.crt
